<html>
 <head>
  <title>IECGW</title>
 <META HTTP-EQUIV="refresh" CONTENT="10">
 </head>
 <body>
  <p>IEC-GW -Interface </p>
  <p>
 <?php
 $address='127.0.0.1';
 $port=5001;
 $sock = socket_create(AF_INET, SOCK_STREAM,  getprotobyname('tcp'));
 echo "connection ",
			(boolval(socket_connect($sock , $address, $port))? 'true':'false' )," <br>";

  $in = "client.list\r\n";
  echo "Sende Request...",$in, "<br>";
  socket_write($sock, $in, strlen($in));
  echo " <br> <br>";
  echo "Lese Response: <br> <br>";
  
  $out = socket_read($sock,2000,PHP_NORMAL_READ);
//  echo $out;
  $cl = substr($out, -2,1);    // gibt anzahl clients zurück
  echo "clients [",$cl,"] <br>";

  for ($i = 0; $i < $cl; $i++) {
 //   echo 'LOOP:',$i,"<br>";
    $out = socket_read($sock,2000,PHP_NORMAL_READ);
    echo $out ,"<br>";
    }  
  socket_close($sock);
 ?>
  </p>
  <a href="p2.php"><img src="new.jpeg" alt="new Client" width="64" height="64"> create new Client</a> 
 </body>
 </html>

