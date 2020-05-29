<?php
  # Two roles are possible amongst members : `static` and `dynamic` servers. To
  # create the right configuration, the current network topology is passed in
  # via serf whenever a new node joins or leaves the network.
  #
  # As per the specification, `static` servers must use sticky sessions, and
  # `dynamic` servers must use round-robin load balancing.

  # Maps a serf line to its IP adress.
  function serf_agent_to_ip($line) {
    $with_port = preg_split('/\s+/', $line)[1];
    return substr($with_port, 0, strpos($with_port, ":"));
  }

  # Maps a serf line to its role. If no role can be found in this line, we
  # return the "unknown" role instead.
  function serf_agent_to_role($line) {
    $exploded = preg_split('/\s+/', $line);
    if (count($exploded) >= 3 && $exploded[2] == "alive") {
      # Syntax is role=something
      # We're only interested in the something.
      $role = substr($exploded[3], strpos($exploded[3], "=") + 1, strlen($exploded[3]));
      # echo $role;
      return $role;
    } else {
      return "unknown";
    }
  }

  # A predicate that indicates if this line represents a static container.
  function static_member($line) {
    return serf_agent_to_role($line) == "static";
  }

  # A predicate that indicates if this line represents a dynamic container.
  function dynamic_member($line) {
    return serf_agent_to_role($line) == "dynamic";
  }

  # Read the standard input.
  $input = stream_get_contents(STDIN);
  $lines = explode("\n", $input);

  # Sort by member type.
  $static_members = array_filter($lines, "static_member");
  $dynamic_members = array_filter($lines, "dynamic_member");

  # Format members to only get their IP adresses.
  $static_ips = array_map("serf_agent_to_ip", $static_members); 
  $dynamic_ips = array_map("serf_agent_to_ip", $dynamic_members);
?>
LogLevel alert rewrite:trace3

<VirtualHost *:80>
  ServerName labo.res.ch

  # Round-robin load balancer, with no routing cookie.
  <Proxy balancer://dynamic-balancer>
<?php
foreach($dynamic_ips as $ip) {
  echo "    BalancerMember http://";
  echo $ip;
  echo ":3000\n";
}
    ?>
    ProxySet lbmethod=byrequests
  </Proxy>

  # Sticky load balancer (as long as the topology does not change too often).
  Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
  <Proxy balancer://static-balancer>
<?php
$route = 1;
foreach($static_ips as $ip) {
  echo "    BalancerMember http://";
  echo $ip;
  echo ":80 route=";
  echo $route;
  echo "\n";
  $route = $route + 1;
}
?>
    ProxySet stickysession=ROUTEID
  </Proxy>

  ProxyPass '/api/transactions' 'balancer://dynamic-balancer'
  ProxyPassReverse '/api/transactions' 'balancer://dynamic-balancer'

  ProxyPass '/' 'balancer://static-balancer/'
  ProxyPassReverse '/' 'balancer://static-balancer/'

</VirtualHost>
