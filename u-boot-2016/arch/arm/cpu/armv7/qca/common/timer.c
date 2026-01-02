/*
 *
 * Copyright (c) 2015-2016, The Linux Foundation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of The Linux Foundation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <asm/io.h>
#include <common.h>
#include <asm/types.h>

#include <watchdog.h>
#include <fdtdec.h>

static unsigned long long timestamp __attribute__((section(".data")));
static unsigned long long lastinc __attribute__((section(".data")));

#define GPT_FREQ_HZ     (ipq_timer.gpt_freq_hz)
#define GPT_FREQ_KHZ	(GPT_FREQ_HZ / 1000)
#define GPT_FREQ	(GPT_FREQ_KHZ / 1000)
#define TIMER_LOAD_VAL  (ipq_timer.timer_load_val)

DECLARE_GLOBAL_DATA_PTR;

/* Information about timer */
static struct ipq_timer_platdata {
	unsigned int gcnt_base;
	unsigned int gcnt_cntcv_lo;
	unsigned int gcnt_cntcv_hi;
	unsigned int gpt_freq_hz;
	unsigned long long timer_load_val;
} ipq_timer __attribute__((section(".data")));

/**
 * timer_init - initialize timer
 */
int timer_init(void)
{
	int nodeoff;

	nodeoff = fdt_path_offset(gd->fdt_blob, "/timer");
	if (nodeoff < 0) {
		WATCHDOG_RESET();
	}

	ipq_timer.gcnt_base = fdtdec_get_uint(gd->fdt_blob, nodeoff,
			"gcnt_base", -1);

	ipq_timer.gcnt_cntcv_lo = fdtdec_get_uint(gd->fdt_blob, nodeoff,
			"gcnt_cntcv_lo", -1);

	ipq_timer.gcnt_cntcv_hi = fdtdec_get_uint(gd->fdt_blob, nodeoff,
			"gcnt_cntcv_hi", -1);

	ipq_timer.gpt_freq_hz = fdtdec_get_uint(gd->fdt_blob, nodeoff,
			"gpt_freq_hz", -1);

	ipq_timer.timer_load_val = fdtdec_get_uint64(gd->fdt_blob, nodeoff,
			"timer_load_val", -1);

	if (ipq_timer.gcnt_base != -1)
		writel(1, ipq_timer.gcnt_base);

	return 0;
}

/**
 * get_timer - returns time lapsed
 * @base: base/start time
 *
 * Returns time lapsed, since the specified base time value.
 */
ulong get_timer(ulong base)
{
	return get_timer_masked() - base;
}

/*
 * read_counter - returns 64-bit counter value
 * Reads Timer HI and Timer LO value register
 */
static unsigned long long read_counter(void)
{
	unsigned long vect_hi1, vect_hi2;
	unsigned long vect_low;

	if(ipq_timer.gcnt_cntcv_hi != 0){
repeat:
		vect_hi1 = readl(ipq_timer.gcnt_cntcv_hi);
		vect_low = readl(ipq_timer.gcnt_cntcv_lo);
		vect_hi2 = readl(ipq_timer.gcnt_cntcv_hi);

		if (vect_hi1 != vect_hi2)
			goto repeat;

		return ((unsigned long long)vect_hi1 << 32 | vect_low);
	}
	else{
		return (readl(ipq_timer.gcnt_cntcv_lo));
	}

}

/* get_ticks - returns the timer coutner */
uint64_t notrace get_ticks(void)
{
	return read_counter();
}

/* get_ticks - returns the timer frequency */
unsigned long get_tbclk(void)
{
        return GPT_FREQ_HZ;
}

/**
 * __udelay -  generates micro second delay.
 * @usec: delay duration in microseconds
 *
 * With 32KHz clock, minimum possible delay is 31.25 Micro seconds and
 * its multiples. In Rumi GPT clock is 32 KHz
 */
void __udelay(unsigned long usec)
{
	unsigned long long val;
	unsigned long long now;
	unsigned long long last;
	unsigned long long runcount;

	if (usec == 0)
		return;

	val = ((unsigned long long)usec * GPT_FREQ_KHZ) / 1000;
	if (val == 0 )
		val = 1; /* Wait for atleast 1 tick */

	last = read_counter();
	do {
		now = read_counter();
		if (last > now)
			runcount = (TIMER_LOAD_VAL - last) + now;
		else
			runcount = now - last;
	} while (runcount < val);
}

static inline unsigned long long gpt_to_sys_freq(unsigned long long gpt)
{
	/*
	 * get_timer() expects the timer increments to be in terms
	 * of CONFIG_SYS_HZ. Convert GPT timer values to CONFIG_SYS_HZ
	 * units.
	 */
	return (gpt) / (GPT_FREQ_HZ / CONFIG_SYS_HZ);
}

/**
 * get_timer_masked - returns current ticks
 *
 * Returns the current timer ticks, since boot.
 */
ulong get_timer_masked(void)
{
	unsigned long long now;
	unsigned long long counter_val;

	counter_val = read_counter();
	now = gpt_to_sys_freq(counter_val);

	if (lastinc <= now) {	/* normal mode (non roll) */
		/* normal mode */
		timestamp += now - lastinc;
		/* move stamp forward with absolute diff ticks */
	} else {
		/* we have overflow of the count down timer */
		timestamp += now + (gpt_to_sys_freq(TIMER_LOAD_VAL) - lastinc);
	}
	lastinc = now;

	return (ulong)timestamp;
}
