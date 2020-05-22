<?php
  # Two roles are possible amongst members : `static` and `dynamic` servers. To
  # create the right configuration, the current network topology is passed in
  # via serf whenever a new node joins or leaves the network.
  #
  # As per the specification, `static` servers must use sticky sessions, and
  # `dynamic` servers must use round-robin load balancing.

  # Maps a serf line to its IP adress.
  function serf_agent_to_ip($line)
  {
    return "";
  }

  # Maps a serf line to its role.
  function serf_agent_to_role($line)
  {
    return "unknown";
  }

  # A predicate that indicates if this line represents a static container.
  function static_member($line)
  {
    return false;
  }

  # A predicate that indicates if this line represents a dynamic container.
  function dynamic_member($line)
  {
    return false;
  }

  # Read the standard input.
  $input = stream_get_contents(STDIN);
  $lines = explode("\n", $str);

  # Sort by member type.
  $static_members = array_filter($lines, "static_member");
  $dynamic_members = array_filter($lines, "dynamic_member");

  # Format members to only get their IP adresses.
  $static_ips = array_map("serf_agent_to_ip", $static_members); 
  $dynamic_ips = array_map("serf_agent_to_ip", $dynamic_members);
?>
<VirtualHost *:80>
  ServerName labo.res.ch

  ProxyPass '/api/transactions/' 'http://<?php print "$dynamic_app"?>/'
  ProxyPassReverse '/api/transactions/' 'http://<?php print "$dynamic_app"?>/'

  ProxyPass '/' 'http://<?php print "$static_app"?>/'
  ProxyPassReverse '/' 'http://<?php print "$static_app"?>/'

</VirtualHost>
