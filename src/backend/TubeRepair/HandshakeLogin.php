<?php 
include "configuration.php";
if(isset($_GET["login"])){
   if($_GET["login"] == 1){
	die("r2=". md5(rand(1, 1000)) . "
hmackr2=" . md5(rand(1, 1000)));
}
if($_GET["login"] == 2){
	die("Auth=". md5(rand(1, 1000)));
}
   if($_GET["login"] == 3){
	die("DeviceId=". md5(rand(1, 1000)) . "
DeviceKey=" . md5(rand(1, 1000)));
}
}