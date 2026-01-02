/*
 * Copyright (c) 2012-2017, The Linux Foundation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted (subject to the limitations in the
 * disclaimer below) provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 *  * Neither the name of [Owner Organization] nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
 * GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
 * HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <common.h>
#include <watchdog.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/gsbi.h>
#include <dm.h>
#include <errno.h>
#include <fdtdec.h>
#include <linux/compiler.h>
#include <asm/io.h>
#include <serial.h>

DECLARE_GLOBAL_DATA_PTR;

extern void qca_serial_init(struct ipq_serial_platdata *pdata);
struct ipq_serial_platdata uart2;
#define FIFO_DATA_SIZE	4


static unsigned int msm_boot_uart_dm_init(unsigned long uart_dm_base);

/* Received data is valid or not */
static int valid_data = 0;
#ifndef CONFIG_DISABLE_CMD_UART
static int uart_valid_data = 0;
#endif

/* Received data */
static unsigned int word = 0;
#ifndef CONFIG_DISABLE_CMD_UART
static unsigned int uart_word = 0;
static unsigned int current_baud_rate = 0;
#endif

/**
 * msm_boot_uart_dm_init_rx_transfer - Init Rx transfer
 * @uart_dm_base: UART controller base address
 */
static unsigned int
msm_boot_uart_dm_init_rx_transfer(unsigned long uart_dm_base)
{
	/* Reset receiver */
	writel(MSM_BOOT_UART_DM_CMD_RESET_RX,
		MSM_BOOT_UART_DM_CR(uart_dm_base));

	/* Enable receiver */
	writel(MSM_BOOT_UART_DM_CR_RX_ENABLE,
		MSM_BOOT_UART_DM_CR(uart_dm_base));
	writel(MSM_BOOT_UART_DM_DMRX_DEF_VALUE,
		MSM_BOOT_UART_DM_DMRX(uart_dm_base));

	/* Clear stale event */
	writel(MSM_BOOT_UART_DM_CMD_RES_STALE_INT,
		MSM_BOOT_UART_DM_CR(uart_dm_base));

	/* Enable stale event */
	writel(MSM_BOOT_UART_DM_GCMD_ENA_STALE_EVT,
		MSM_BOOT_UART_DM_CR(uart_dm_base));

	return MSM_BOOT_UART_DM_E_SUCCESS;
}

/**
 * msm_boot_uart_dm_read - reads a word from the RX FIFO.
 * @data: location where the read data is stored
 * @count: no of valid data in the FIFO
 * @wait: indicates blocking call or not blocking call
 *
 * Reads a word from the RX FIFO. If no data is available blocks if
 * @wait is true, else returns %MSM_BOOT_UART_DM_E_RX_NOT_READY.
 */
static unsigned int
msm_boot_uart_dm_read(unsigned int *data, int *count, int wait,
			unsigned long base)
{
	static int total_rx_data = 0;
	static int rx_data_read = 0;
	uint32_t status_reg;

	if (data == NULL)
		return MSM_BOOT_UART_DM_E_INVAL;

	status_reg = readl(MSM_BOOT_UART_DM_MISR(base));

	/* Check for DM_RXSTALE for RX transfer to finish */
	while (!(status_reg & MSM_BOOT_UART_DM_RXSTALE)) {
		status_reg = readl(MSM_BOOT_UART_DM_SR(base));
		if((status_reg & MSM_BOOT_UART_DM_RX_STALE_TIMEOUT) && \
			(status_reg & MSM_BOOT_UART_DM_SR_RXFULL)) {
			printf("Console buffer overflow occured!!");
			msm_boot_uart_dm_init_rx_transfer(base);
			total_rx_data = rx_data_read = 0;
			return MSM_BOOT_UART_DM_E_RX_NOT_READY;
		}

		status_reg = readl(MSM_BOOT_UART_DM_MISR(base));
		if (!wait)
			return MSM_BOOT_UART_DM_E_RX_NOT_READY;
	}

	/* Check for Overrun error. We'll just reset Error Status */
	if (readl(MSM_BOOT_UART_DM_SR(base)) &
			MSM_BOOT_UART_DM_SR_UART_OVERRUN) {
		writel(MSM_BOOT_UART_DM_CMD_RESET_ERR_STAT,
			MSM_BOOT_UART_DM_CR(base));
		total_rx_data = rx_data_read = 0;
		msm_boot_uart_dm_init(base);
		return MSM_BOOT_UART_DM_E_RX_NOT_READY;
	}

	/* Read UART_DM_RX_TOTAL_SNAP for actual number of bytes received */
	if (total_rx_data == 0)
		total_rx_data =  readl(MSM_BOOT_UART_DM_RX_TOTAL_SNAP(base));

	/* Data available in FIFO; read a word. */
	*data = readl(MSM_BOOT_UART_DM_RF(base, 0));

	/* WAR for http://prism/CR/548280 */
	if (*data == 0) {
		return MSM_BOOT_UART_DM_E_RX_NOT_READY;
	}

	/* increment the total count of chars we've read so far */
	rx_data_read += FIFO_DATA_SIZE;

	/* actual count of valid data in word */
	*count = ((total_rx_data < rx_data_read) ?
			(FIFO_DATA_SIZE - (rx_data_read - total_rx_data)) :
			FIFO_DATA_SIZE);

	/* If there are still data left in FIFO we'll read them before
	 * initializing RX Transfer again
	 */
	if (rx_data_read < total_rx_data)
		return MSM_BOOT_UART_DM_E_SUCCESS;

	msm_boot_uart_dm_init_rx_transfer(base);
	total_rx_data = rx_data_read = 0;

	return MSM_BOOT_UART_DM_E_SUCCESS;
}

/**
 * msm_boot_uart_replace_lr_with_cr - replaces "\n" with "\r\n"
 * @data_in:      characters to be converted
 * @num_of_chars: no. of characters
 * @data_out:     location where converted chars are stored
 *
 * Replace linefeed char "\n" with carriage return + linefeed
 * "\r\n". Currently keeping it simple than efficient.
 */
static unsigned int
msm_boot_uart_replace_lr_with_cr(const char *data_in,
                                 int num_of_chars,
                                 char *data_out, int *num_of_chars_out)
{
        int i = 0, j = 0;

        if ((data_in == NULL) || (data_out == NULL) || (num_of_chars < 0))
                return MSM_BOOT_UART_DM_E_INVAL;

        for (i = 0, j = 0; i < num_of_chars; i++, j++) {
                if (data_in[i] == '\n')
                        data_out[j++] = '\r';

                data_out[j] = data_in[i];
        }

        *num_of_chars_out = j;

        return MSM_BOOT_UART_DM_E_SUCCESS;
}

/**
 * msm_boot_uart_dm_write - transmit data
 * @data:          data to transmit
 * @num_of_chars:  no. of bytes to transmit
 *
 * Writes the data to the TX FIFO. If no space is available blocks
 * till space becomes available.
 */
static unsigned int
msm_boot_uart_dm_write(const char *data, unsigned int num_of_chars,
			unsigned long base)
{
	unsigned int tx_word_count = 0;
	unsigned int tx_char_left = 0, tx_char = 0;
	unsigned int tx_word = 0;
	int i = 0;
	char *tx_data = NULL;
	char new_data[1024];

        if ((data == NULL) || (num_of_chars <= 0))
                return MSM_BOOT_UART_DM_E_INVAL;

        /* Replace line-feed (/n) with carriage-return + line-feed (/r/n) */
        msm_boot_uart_replace_lr_with_cr(data, num_of_chars, new_data, &i);

        tx_data = new_data;
        num_of_chars = i;

        /* Write to NO_CHARS_FOR_TX register number of characters
        * to be transmitted. However, before writing TX_FIFO must
        * be empty as indicated by TX_READY interrupt in IMR register
        */
        /* Check if transmit FIFO is empty.
        * If not we'll wait for TX_READY interrupt. */

        if (!(readl(MSM_BOOT_UART_DM_SR(base)) & MSM_BOOT_UART_DM_SR_TXEMT)) {
                while (!(readl(MSM_BOOT_UART_DM_ISR(base)) & MSM_BOOT_UART_DM_TX_READY))
                        __udelay(1);
        }

        /* We are here. FIFO is ready to be written. */
        /* Write number of characters to be written */
        writel(num_of_chars, MSM_BOOT_UART_DM_NO_CHARS_FOR_TX(base));

        /* Clear TX_READY interrupt */
        writel(MSM_BOOT_UART_DM_GCMD_RES_TX_RDY_INT, MSM_BOOT_UART_DM_CR(base));

        /* We use four-character word FIFO. So we need to divide data into
        * four characters and write in UART_DM_TF register */
        tx_word_count = (num_of_chars % 4) ? ((num_of_chars / 4) + 1) :
                        (num_of_chars / 4);
        tx_char_left = num_of_chars;

        for (i = 0; i < (int)tx_word_count; i++) {
                tx_char = (tx_char_left < 4) ? tx_char_left : 4;
                PACK_CHARS_INTO_WORDS(tx_data, tx_char, tx_word);

                /* Wait till TX FIFO has space */
                while (!(readl(MSM_BOOT_UART_DM_SR(base)) & MSM_BOOT_UART_DM_SR_TXRDY))
                        __udelay(1);

                /* TX FIFO has space. Write the chars */
                writel(tx_word, MSM_BOOT_UART_DM_TF(base, 0));
                tx_char_left = num_of_chars - (i + 1) * 4;
                tx_data = tx_data + 4;
        }

        return MSM_BOOT_UART_DM_E_SUCCESS;
}

/*
 * msm_boot_uart_dm_reset - resets UART controller
 * @base: UART controller base address
 */
static unsigned int msm_boot_uart_dm_reset(unsigned long base)
{
	writel(MSM_BOOT_UART_DM_CMD_RESET_RX, MSM_BOOT_UART_DM_CR(base));
	writel(MSM_BOOT_UART_DM_CMD_RESET_TX, MSM_BOOT_UART_DM_CR(base));
	writel(MSM_BOOT_UART_DM_CMD_RESET_ERR_STAT, MSM_BOOT_UART_DM_CR(base));
	writel(MSM_BOOT_UART_DM_CMD_RES_TX_ERR, MSM_BOOT_UART_DM_CR(base));
	writel(MSM_BOOT_UART_DM_CMD_RES_STALE_INT, MSM_BOOT_UART_DM_CR(base));

	return MSM_BOOT_UART_DM_E_SUCCESS;
}

/*
 * msm_boot_uart_dm_init - initilaizes UART controller
 * @uart_dm_base: UART controller base address
 */
static unsigned int msm_boot_uart_dm_init(unsigned long uart_dm_base)
{
	/* Configure UART mode registers MR1 and MR2 */
	/* Hardware flow control isn't supported */
	writel(0x0, MSM_BOOT_UART_DM_MR1(uart_dm_base));

	/* 8-N-1 configuration: 8 data bits - No parity - 1 stop bit */
	writel(MSM_BOOT_UART_DM_8_N_1_MODE, MSM_BOOT_UART_DM_MR2(uart_dm_base));

	/* Configure Interrupt Mask register IMR */
	writel(MSM_BOOT_UART_DM_IMR_ENABLED, MSM_BOOT_UART_DM_IMR(uart_dm_base));

	/*
	 * Configure Tx and Rx watermarks configuration registers
	 * TX watermark value is set to 0 - interrupt is generated when
	 * FIFO level is less than or equal to 0
	 */
	writel(MSM_BOOT_UART_DM_TFW_VALUE, MSM_BOOT_UART_DM_TFWR(uart_dm_base));

	/* RX watermark value */
	writel(MSM_BOOT_UART_DM_RFW_VALUE, MSM_BOOT_UART_DM_RFWR(uart_dm_base));

	/* Configure Interrupt Programming Register */
	/* Set initial Stale timeout value */
	writel(MSM_BOOT_UART_DM_STALE_TIMEOUT_LSB,
		MSM_BOOT_UART_DM_IPR(uart_dm_base));

	/* Configure IRDA if required */
	/* Disabling IRDA mode */
	writel(0x0, MSM_BOOT_UART_DM_IRDA(uart_dm_base));

	/* Configure hunt character value in HCR register */
	/* Keep it in reset state */
	writel(0x0, MSM_BOOT_UART_DM_HCR(uart_dm_base));

	/*
	 * Configure Rx FIFO base address
	 * Both TX/RX shares same SRAM and default is half-n-half.
	 * Sticking with default value now.
	 * As such RAM size is (2^RAM_ADDR_WIDTH, 32-bit entries).
	 * We have found RAM_ADDR_WIDTH = 0x7f
	 */

	/* Issue soft reset command */
	msm_boot_uart_dm_reset(uart_dm_base);

	/* Enable/Disable Rx/Tx DM interfaces */
	/* Data Mover not currently utilized. */
	writel(0x0, MSM_BOOT_UART_DM_DMEN(uart_dm_base));

	/* Enable transmitter */
	writel(MSM_BOOT_UART_DM_CR_TX_ENABLE,
		MSM_BOOT_UART_DM_CR(uart_dm_base));

	/* Initialize Receive Path */
	msm_boot_uart_dm_init_rx_transfer(uart_dm_base);

	return 0;
}

/**
 * uart_dm_init - initializes UART
 *
 * Initializes clocks, GPIO and UART controller.
 */
static void ipq_serial_init(struct ipq_serial_platdata *plat,
				unsigned long base)
{
	qca_serial_init(plat);
	writel(plat->bit_rate, MSM_BOOT_UART_DM_CSR(base));

	/* Intialize UART_DM */
	msm_boot_uart_dm_init(base);
}

/**
 * ipq_serial_wait_tx_empty - Wait until TX FIFO is empty
 */
void ipq_serial_wait_tx_empty(void)
{
	struct udevice *dev = gd->cur_serial_dev;
	struct ipq_serial_platdata *plat = dev->platdata;
	unsigned long base = plat->reg_base;

        while (!(readl(MSM_BOOT_UART_DM_SR(base)) & MSM_BOOT_UART_DM_SR_TXEMT))
		__udelay(1);
}

/**
 * serial_tstc - checks if data available for reading
 *
 * Returns 1 if data available, 0 otherwise
 */
static int ipq_serial_pending(struct udevice *dev, bool input)
{
	struct ipq_serial_platdata *plat = dev->platdata;
	unsigned long base = plat->reg_base;

	/* Return if data is already read */
	if (valid_data)
		return 1;

	/* Read data from the FIFO */
	if (msm_boot_uart_dm_read(&word, &valid_data, 0, base) != MSM_BOOT_UART_DM_E_SUCCESS)
		return 0;

	return 1;
}

/**
 * serial_getc - reads a character
 *
 * Returns the character read from serial port.
 */
static int ipq_serial_getc(struct udevice *dev)
{
	int byte;

	while (!ipq_serial_pending(dev, true)) {
		WATCHDOG_RESET();
		/* wait for incoming data */
	}

	byte = (int)word & 0xff;
	word = word >> 8;
	valid_data--;

	return byte;
}

/*
 * serial_setbrg - sets serial baudarate
 */
static int ipq_serial_setbrg(struct udevice *dev, int baudrate)
{
	return 0;
}

static int ipq_serial_putc(struct udevice *dev, const char ch)
{
	struct ipq_serial_platdata *plat = dev->platdata;
	unsigned long base = plat->reg_base;

	return msm_boot_uart_dm_write(&ch, 1, base);
}

static int ipq_serial_probe(struct udevice *dev)
{
	struct ipq_serial_platdata *plat = dev->platdata;
	unsigned long base = plat->reg_base;

	ipq_serial_init(plat, base);

	return 0;
}

static int ipq_serial_ofdata_to_platdata(struct udevice *dev)
{
	struct ipq_serial_platdata *plat = dev->platdata;
	fdt_addr_t addr;

	addr = dev_get_addr(dev);
	if (addr == FDT_ADDR_T_NONE)
		return -EINVAL;

	plat->reg_base = addr;
	plat->port_id = fdtdec_get_int(gd->fdt_blob, dev->of_offset, "id", -1);
	plat->bit_rate = fdtdec_get_int(gd->fdt_blob, dev->of_offset,
			"bit_rate", -1);
	plat->m_value = fdtdec_get_int(gd->fdt_blob, dev->of_offset, "m_value", -1);
	plat->n_value = fdtdec_get_int(gd->fdt_blob, dev->of_offset, "n_value", -1);
	plat->d_value = fdtdec_get_int(gd->fdt_blob, dev->of_offset, "d_value", -1);

	plat->gpio_node = fdt_subnode_offset(gd->fdt_blob, dev->of_offset, "serial_gpio");

	return 0;
}

static const struct dm_serial_ops ipq_serial_ops = {
	.putc = ipq_serial_putc,
	.pending = ipq_serial_pending,
	.getc = ipq_serial_getc,
	.setbrg = ipq_serial_setbrg,
};

static const struct udevice_id ipq_serial_ids[] = {
	{ .compatible = "qca,ipq-uartdm" },
	{ }
};

U_BOOT_DRIVER(serial_ipq) = {
	.name   = "serial_ipq",
	.id     = UCLASS_SERIAL,
	.of_match = ipq_serial_ids,
	.ofdata_to_platdata = ipq_serial_ofdata_to_platdata,
	.platdata_auto_alloc_size = sizeof(struct ipq_serial_platdata),
	.probe = ipq_serial_probe,
	.ops    = &ipq_serial_ops,
	.flags = DM_FLAG_PRE_RELOC,
};

#ifndef CONFIG_DISABLE_CMD_UART
/**
 * do_uartwr - transmits a string of data
 * @s: string to transmit
 */
static int do_uartwr(char *str)
{
	unsigned long base = uart2.reg_base;

	while (*str != '\0')
		msm_boot_uart_dm_write(str++, 1, base);
	return 0;
}

static int uart_serial_tstc(void)
{
	unsigned long base = uart2.reg_base;
	/* Return if data is already read */
	if (uart_valid_data)
		return 1;

	/* Read data from the FIFO */
	if (msm_boot_uart_dm_read(&uart_word, &uart_valid_data, 0,
		base) != MSM_BOOT_UART_DM_E_SUCCESS)
		return 0;

	return 1;
}

static int do_uartrd(void)
{
	int byte;

	for (;;) {
		while (!uart_serial_tstc()) {
			/* wait for incoming data */
		}
		byte = (int)uart_word & 0xff;
		switch (byte) {
			case 0x03:
				uart_word = uart_word >> 8;
				uart_valid_data--;
				return (-1);
			default:
				serial_putc(byte);
		}
		uart_word = uart_word >> 8;
		uart_valid_data--;
	}
	return 0;
}

static void  do_uart_start(void)
{
	int node;
	const u32 *uart_base;
	int len;

	node = fdt_path_offset(gd->fdt_blob, "uart2");
	if (node < 0) {
		printf("2nd UART : Not found, skipping initialization\n");
		return;
	}

	uart_base = fdt_getprop(gd->fdt_blob, node, "reg", &len);
	if (uart_base == NULL) {
		printf("UART init failed. Unable to get uart_base\n");
		return;
	}

	uart2.reg_base = fdt32_to_cpu(uart_base[0]);

	uart2.port_id = fdtdec_get_int(gd->fdt_blob, node, "id", -1);
	uart2.bit_rate = fdtdec_get_int(gd->fdt_blob, node,
			"bit_rate", -1);
	uart2.clk_rate = fdtdec_get_int(gd->fdt_blob, node,
			"clk_rate", -1);
	uart2.m_value = fdtdec_get_int(gd->fdt_blob, node, "m_value", -1);
	uart2.n_value = fdtdec_get_int(gd->fdt_blob, node, "n_value", -1);
	uart2.d_value = fdtdec_get_int(gd->fdt_blob, node, "d_value", -1);

	uart2.gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "serial_gpio");
	ipq_serial_init(&uart2,  uart2.reg_base);
}

static const unsigned int baud_table[] = {
	150, 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 57600, 115200
};

static int find_baud_rate(unsigned int baud_rate)
{
	int i;

	for (i=0; i<ARRAY_SIZE(baud_table); i++)
	{
		if(baud_rate == baud_table[i])
			return 1;
	}

	return 0;
}

struct msm_baud_map {
        u16     divisor;
        u8      code;
};

static void set_baud_rate(unsigned int baud)
{
	unsigned int divisor;
	const struct msm_baud_map *entry, *end;
	static const struct msm_baud_map table[] = {
		{    1, 0xff },
		{    2, 0xee },
		{    3, 0xdd },
		{    4, 0xcc },
		{    6, 0xbb },
		{    8, 0xaa },
		{   12, 0x99 },
		{   16, 0x88 },
		{   24, 0x77 },
		{   32, 0x66 },
		{   48, 0x55 },
		{   96, 0x44 },
		{  192, 0x33 },
		{  384, 0x22 },
		{  768, 0x11 },
		{ 1536, 0x00 },
	};

	if (uart2.clk_rate == 0)
	{
		printf("Second uart is not initialised\n");
		return;
	}

	divisor = uart2.clk_rate / baud / 16;
	end = table + ARRAY_SIZE(table);
	entry = table;
	while (entry < end) {
		if (entry->divisor == divisor) {
			writel(entry->code, MSM_BOOT_UART_DM_CSR(uart2.reg_base));
			current_baud_rate = baud;
			break;
		}
		entry++;
	}

}

/******************************************************************************
 * uart command intepreter
 */
static int do_uart(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	int i;
	unsigned int baud_rate;

	if (argc < 2)
		return CMD_RET_USAGE;

	if (strncmp(argv[1], "start", 5) == 0) {
		printf("starting second UART...\n");
		do_uart_start();
		return 0;
	}

	if (strcmp(argv[1], "read") == 0) {
		if (argc == 2) {
			do_uartrd();
			return 0;
		}
	}

	if (strcmp(argv[1], "write") == 0) {
		if (argc == 3) {
			do_uartwr(argv[2]);
			return 0;
		}
	}

	if (strcmp(argv[1], "baud_rate") == 0) {
		if (argc == 3) {
			baud_rate = simple_strtoul(argv[2], NULL, 10);

			if (!find_baud_rate(baud_rate)) {
				printf("Invalid baud rate %d\n", baud_rate);
				printf("The supported rates are:");
				for (i=0; i<ARRAY_SIZE(baud_table); i++)
					printf("%d ", baud_table[i]);
				return -1;
			}
			set_baud_rate(baud_rate);
		} else {
			printf("The current baud rate is: %d\n", current_baud_rate);
		}
		return 0;
	}

	return CMD_RET_USAGE;
}
U_BOOT_CMD(
	uart,	3,	1,	do_uart,
	"UART sub-system",
	"start - start UART controller\n"
	"uart read - read strings from second UART\n"
	"uart write - write strings to second UART\n"
	"uart baud_rate [rate] - show or set second UART baud rates\n"
);
#endif
