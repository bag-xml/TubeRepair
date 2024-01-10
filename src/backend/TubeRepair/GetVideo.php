<?php
include "configuration.php";
$videoID = $_GET['videoId'];
if(strlen($videoID) > 2){
	header("Location: https://$invidiousURL/latest_version?id=" . $videoID);
}