node '<node>' {
	class{ "nginx": } 
		

	nginx::resource::server { '<FQDN>':
		listen_port => 80,
		ssl_redirect => true,
		ssl	=> true,
		ssl_cert => '<cert path>',
		ssl_key	=> '<key path>',
		proxy	=> '<destination server, HTTP>', # for example: http://172.16.52.2
		proxy_set_header => ['X-Forwarded-Proto $scheme'],
	}	
		
 	nginx::resource::location { '/<resource>/':
    		proxy => '<destination server, HTTP>', # for example: http://172.16.1.30:3000
    		server => '<FQDN>',
		ssl_only => true,
	}	
	
	nginx::resource::server {'forward_proxy':
		listen_port => 8080,
		resolver => ['8.8.8.8'], # needed for DNS resolution
		proxy => 'http://$http_host$request_uri',
		format_log => 'time_taken', # in case you need special logging requirements
	}
	
}
  file { '/etc/nginx/conf.d/custom_log_parameters.conf':
    		ensure => 'file',
		owner  => 'root',
		group  => 'root',
		mode   => '0644',
    		content => 'log_format  time_taken  \'$remote_addr - $remote_user [$time_local] "$request" \'
                    \'request_time=$request_time $status $body_bytes_sent "$http_referer" \' # with the first parameter we are logging the time it takes for a request to accomplish
                    \'"$http_user_agent" "$http_x_forwarded_for"\';
',
   }
	
	# health checks:

	exec { 'Checking reverse_proxy health':
		command => '/usr/bin/curl -skIL https://<FQDN> &>/dev/null || echo "Reverse proxy is failing at $(hostname). Please review." | /usr/bin/mailx <user>@<domain>',
		onlyif => '/usr/bin/test -f /var/run/nginx.pid', 
	}	
	
	exec { 'Checking forward_proxy health':
		command => '/usr/bin/curl -x http://localhost:8080 -I <any HTTP webserver> &>/dev/null || echo "Forward proxy is failing at $(hostname). Please review." | /usr/bin/mailx <user>@<domain>',
		onlyif => '/usr/bin/test -f /var/run/nginx.pid',
	}
