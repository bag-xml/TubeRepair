<?php
//Maintenance
$underMaintenance = false; // put the server in maintenance
//config
$skipHandshakeLogin = false; // skip the handshake when opening the app
$invidiousURL = "invidious.fdn.fr"; // TubeRepair uses an invidious endpoint to get youtube videos. if the default doesnt work please find one here: https://docs.invidious.io/instances/
$APIkey = "AIzaSyDXpueywmjWFGVSjrn6031NaTqZszxI_Rw"; // insert your api key here!
$baseURL = "www.google.com"; // enter your url where this is hosted NOTE: without any / with http/s
$serverScriptDirectory = "TubeRepair"; // please input the correct directory where your server scripts are located!
$APIurl = "www.googleapis.com"; //incase they change the api to a new url you can input it here
$MaxCount = 10; // the amount of results the api will search for (max 50)
$maxCommentCountResult = 50; // the amount of comments the api will retrieve (max 50)