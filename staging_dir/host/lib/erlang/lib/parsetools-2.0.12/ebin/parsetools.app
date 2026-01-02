{application, parsetools,
 [{description, "XLATETOOLS  CXC 138 xx"},
  {vsn, "2.0.12"},
  {modules, [leex,
             yecc,
	     yeccparser,
	     yeccscan
	    ]
  },
  {registered,[]},
  {applications, [kernel,stdlib]},
  {env, [{file_util_search_methods,[{"", ""}, {"ebin", "esrc"}, {"ebin", "src"}]}
	]
  },
  {runtime_dependencies, ["stdlib-2.0","kernel-3.0","erts-6.0"]}
 ]
}. 
 
















