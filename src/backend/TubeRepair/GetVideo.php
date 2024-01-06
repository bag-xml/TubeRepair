<?php
$videoID = $_GET['videoId'];
if(strlen($videoID) > 2){
	header("Location: https://yewtu.be/latest_version?id=" . $videoID);
}