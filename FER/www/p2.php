<html>
 <head>
  <title>IECGW</title>
 <meta http-equiv="refresh" content="3; url=p1.php" />
</head>
 <body>
  <p>create an new client </p>
  <p>
 <?php
 $address='127.0.0.1';
 $port=5001;
 $sock = socket_create(AF_INET, SOCK_STREAM,  getprotobyname('tcp'));
 echo "connection ",
			(boolval(socket_connect($sock , $address, $port))? 'true':'false' )," <br>";

  $in = "client.add\r\n";
  echo "Sende Request...",$in, "<br>";
  socket_write($sock, $in, strlen($in));
  echo " <br> <br>";
  echo "Lese Response: <br> <br>";

  socket_close($sock);
 ?>
  </p>
 </body>
 </html>

