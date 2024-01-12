<?php 
include "configuration.php";
if(isset($_GET["videoId"])){
	if(isset($_SERVER['HTTP_X_TUBEREPAIR_API_KEY'])){ $APIkey = $_SERVER['HTTP_X_TUBEREPAIR_API_KEY'];}else{exit;}
$curlConnectionInitialization = curl_init("https://" . $APIurl . "/youtube/v3/commentThreads?part=snippet&maxResults=". $maxCommentCountResult."&videoId=" . $_GET["videoId"] ."&key=" . $APIkey);
curl_setopt($curlConnectionInitialization, CURLOPT_HEADER, 0);
curl_setopt($curlConnectionInitialization, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($curlConnectionInitialization);
if(curl_error($curlConnectionInitialization)) {
  exit;
}
$decodeResponce = json_decode($response, true);
$kindResponse = json_decode($response, false)->kind;
if($kindResponse == "youtube#commentThreadListResponse"){
	$maxResultsFromYT = $decodeResponce['pageInfo']['resultsPerPage'];
	$entries = "";
	for($i = 0; $i<$maxResultsFromYT; $i++){
	$commentID = $decodeResponce['items'][$i]['id'];
	$commentVideoId = $decodeResponce['items'][$i]['snippet']['videoId'];
	$channelname = $decodeResponce['items'][$i]['snippet']['topLevelComment']['snippet']['authorDisplayName'];
	//$description = $decodeResponce['items'][$i]['snippet']['description'];
	$text = $decodeResponce['items'][$i]['snippet']['topLevelComment']['snippet']['textDisplay'];
	
	$publishDate = rtrim($decodeResponce['items'][$i]['snippet']['topLevelComment']['snippet']['publishedAt'], 'Z') . ".000Z";
	$channelId = $decodeResponce['items'][$i]['snippet']['topLevelComment']['snippet']['authorChannelId']['value'];
	$etag = $decodeResponce['items'][$i]['etag'];
	$defaultTHURL = $decodeResponce['items'][$i]['snippet']['topLevelComment']['snippet']['authorProfileImageUrl'];
$entryASYoutube = <<<Entry
<entry gd:etag='$etag'>
		<id>tag:youtube.com,2008:video:$commentVideoId:comment:$commentID</id>
		<published>$publishDate</published>
		<updated>$publishDate</updated>
		<category scheme='http://schemas.google.com/g/2005#kind' term='http://gdata.youtube.com/schemas/2007#comment'/>
		<title>Comment from $channelname</title>
		<content>﻿$text</content>
		<link rel='related' type='application/atom+xml' href='http://gdata.youtube.com/feeds/api/videos/$commentVideoId?v=2'/>
		<link rel='alternate' type='text/html' href='http://www.youtube.com/watch?v=$commentVideoId'/>
		<link rel='self' type='application/atom+xml' href='http://gdata.youtube.com/feeds/api/videos/$commentVideoId/comments/$commentID?v=2'/>
		<author>
			<name>$channelname</name>
			<uri>http://gdata.youtube.com/feeds/api/users/$channelId</uri>
			<yt:userId>$channelId</yt:userId>
		</author>
		<yt:channelId>$channelId</yt:channelId>
		<yt:replyCount>1</yt:replyCount>
		<yt:videoid>$commentVideoId</yt:videoid>
	</entry>
Entry;
    if(str_contains($_SERVER["HTTP_USER_AGENT"], "com.google.ios")){
      $entries = $entries . $entryASYoutube;
    }
    else{
	$entries = $entries . $entryClassicTube;
    }
	}
$youtubeXML = <<<XML
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:openSearch="http://a9.com/-/spec/opensearch/1.1/" xmlns:yt="http://gdata.youtube.com/schemas/2007" xmlns:media="http://search.yahoo.com/mrss/" gd:etag="">
  <id>http://gdata.youtube.com/feeds/api/standardfeeds/US/recently_featured</id>
  <category scheme="http://schemas.google.com/g/2005#kind" term="http://gdata.youtube.com/schemas/2007/#video" />
<title>Spotlight Videos</title>  <logo>http://www.gstatic.com/youtube/img/logo.png</logo>
  <link rel="http://schemas.google.com/g/2005#feed" type="application/atom+xml" href="https://$baseURL/feeds/api/standardfeeds/US/recently_featured" />
  <link rel="http://schemas.google.com/g/2005#batch" type="application/atom+xml" href="https://$baseURL/feeds/api/standardfeeds/US/recently_featured/batch" />
  <link rel="self" type="application/atom+xml" href="https://$baseURL/feeds/api/standardfeeds/US/recently_featured?start-index=1&amp;max-results=25&amp;format=2,3,8,9&amp;fields=openSearch:totalResults,openSearch:startIndex,openSearch:itemsPerPage,link%5B@rel=&#039;http://schemas.google.com/g/2005%23batch&#039;%5D,entry(id,title,updated,published,yt:rating,link%5B@rel=&#039;edit&#039;%20or%20@rel=&#039;https://$baseURL/schemas/2007%23video.ratings&#039;%5D,yt:statistics(@viewCount),batch:status,yt:accessControl%5B@action=&#039;list&#039;%5D,media:group(media:thumbnail,media:content%5B@yt:format=&#039;2&#039;%20or%20@yt:format=&#039;3&#039;%20or%20@yt:format=&#039;8&#039;%20or%20@yt:format=&#039;9&#039;%5D(@yt:format,@url,@duration),media:category,media:player,media:description,media:keywords,media:rating,yt:videoid,media:credit,yt:private),app:control,gd:comments)" />
  <!-- <link rel="service" type="application/atomsvc+xml" href="https://$baseURL/feeds/api/standardfeeds/US/recently_featured?alt=atom-service" /> -->
  <author>
    <name>Credits:TubeFixer</name>
    <uri>https://mali357.gay/</uri>
  </author>
<openSearch:totalResults>$maxResultsFromYT</openSearch:totalResults>
  <openSearch:itemsPerPage>25</openSearch:itemsPerPage>
  <openSearch:startIndex>1</openSearch:startIndex>
  $entries
  <debug>$response</debug>
</feed>
XML;
die($youtubeXML);
}
else{
	
die("An internal server error has occured! If there is a new version of the server please update to the latest version! Error: " . $response);
}
curl_close($curlConnectionInitialization);	
}

function getDescription($videoId){
	$decodeResponce['items'][0]['snippet']['description'];
} 