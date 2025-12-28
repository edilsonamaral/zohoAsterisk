#!/usr/bin/php

<?php

$ip = '72.188.200.140'; //or any other IP here
$s = file_get_contents('http://ip2c.org/'.$ip);
switch($s[0])
{
  case '0':
    echo 'Something wrong';
    break;
  case '1':
    $reply = explode(';',$s);
    echo 'Two-letter: '.$reply[1]."\n";
    echo 'Three-letter: '.$reply[2]."\n";
    echo 'Full name: '.$reply[3]."\n";
    break;
  case '2':
    echo 'Not found in database';
    break;
}

?>
