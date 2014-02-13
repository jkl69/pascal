#!/usr/bin/php -q

<?php
/* Define STDIN in case if it is not already defined by PHP for some reason */
/*
if(!defined("STDIN")) {
     define("STDIN", fopen('php://stdin','r'));
     }   
 
echo "Hello! What is your name (enter below):\n";
$strName = fread(STDIN, 80); // Read up to 80 characters or a newline
echo 'Hello ' , $strName , "\n";
*/
$address='127.0.0.1';
$port=5001;

$sock = socket_create(AF_INET, SOCK_STREAM,  getprotobyname('tcp'));
// socket_set_option($socket, SOL_SOCKET, SO_SNDTIMEO, array('sec' => $seconds, 'usec' => $milliseconds));
echo socket_connect($sock , $address, $port);
$in = "client.list\r\n";
//$in .= "Host: www.example.com\r\n";
$out = '';

echo "Sende Request...",$in;
socket_write($sock, $in, strlen($in));
echo "OK.\n";
echo "Lese Response:\n\n";

$buf = 'Dies ist mein Puffer.';
$out = socket_read($sock,2000,PHP_NORMAL_READ);
echo $out;
$cl = substr($out, -2,1);    // gibt anzahl clients zurück
echo "clients [",$cl,"]\n";
$out = socket_read($sock,2000,PHP_NORMAL_READ);
echo $out;
socket_close($sock);

?>

