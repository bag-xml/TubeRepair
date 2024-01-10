<?php 
include "configuration.php";
if(isset($_GET["q"]) && !isset($_GET["v"])){
$curlConnectionInitialization = curl_init("https://" . $APIurl . "/youtube/v3/search?part=snippet&order=relevance&maxResults=" . $MaxCount . "&q=" . preg_replace('/\s+/', '', $_GET["q"]) ."&type=channel&key=" . $APIkey);
curl_setopt($curlConnectionInitialization, CURLOPT_HEADER, 0);
curl_setopt($curlConnectionInitialization, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($curlConnectionInitialization);
if(curl_error($curlConnectionInitialization)) {
  exit;
}
$decodeResponce = json_decode($response, true);
$kindResponse = json_decode($response, false)->kind;
if($kindResponse == "youtube#searchListResponse"){
	$maxResultsFromYT = $decodeResponce['pageInfo']['resultsPerPage'];
	$entries = "";
	for($i = 0; $i<$maxResultsFromYT; $i++){
	//$videoID = $decodeResponce['items'][$i]['id']['videoId'];
	$channelTitle = $decodeResponce['items'][$i]['snippet']['channelTitle'];
	$channelname = $decodeResponce['items'][$i]['snippet']['title'];
	//$description = $decodeResponce['items'][$i]['snippet']['description'];
	$description = "Not Supported!";
	$videoname = $decodeResponce['items'][$i]['snippet']['title'];
	$publishDate = $decodeResponce['items'][$i]['snippet']['publishedAt'];
	$channelId = $decodeResponce['items'][$i]['snippet']['channelId'];
	$etag = $decodeResponce['items'][$i]['etag'];
	$defaultTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['default']['url'];
	$mediumTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['medium']['url'];
	$highTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['high']['url'];
	$entry = <<<Entry
		<entry gd:etag='W/&quot;Ck8GRH47eCp7I2A9XRdTGEQ.&quot;'>
		<id>tag:youtube.com,2008:channel:s3JgJcFG2o-NH3T63vo-qg</id>
		<updated>2014-09-16T18:07:05.000Z</updated>
		<category scheme='http://schemas.google.com/g/2005#kind' term='http://gdata.youtube.com/schemas/2007#channel'/>
		<title>$channelTitle</title>
		<summary>$description</summary>
		<link rel='http://gdata.youtube.com/schemas/2007#featured-video' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/videos/YM582qGZHLI?v=2'/>
		<link rel='alternate' type='text/html' href='https://www.youtube.com/channel/UCs3JgJcFG2o-NH3T63vo-qg'/>
		<link rel='self' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/channels/s3JgJcFG2o-NH3T63vo-qg?v=2'/>
		<author>
			<name>$channelname</name>
			<uri>https://gdata.youtube.com/feeds/api/users/webauditors</uri>
			<yt:userId>s3JgJcFG2o-NH3T63vo-qg</yt:userId>
		</author>
		<yt:channelId>$channelId</yt:channelId>
		<yt:channelStatistics subscriberCount='0' viewCount='0'/>
		<gd:feedLink rel='http://gdata.youtube.com/schemas/2007#channel.content' href='https://gdata.youtube.com/feeds/api/users/webauditors/uploads?v=2' countHint='0'/>
		<media:thumbnail url='$defaultTHURL'/>
	</entry>
Entry;
   $entries = $entries . $entry;
	}
$youtubeXML = <<<XML
	<?xml version='1.0' encoding='UTF-8'?>
<feed
	xmlns='http://www.w3.org/2005/Atom'
	xmlns:gd='http://schemas.google.com/g/2005'
	xmlns:openSearch='http://a9.com/-/spec/opensearch/1.1/'
	xmlns:yt='http://gdata.youtube.com/schemas/2007'
	xmlns:media='http://search.yahoo.com/mrss/' gd:etag='W/&quot;DkcBQ3g-fip7I2A9XRRXEUw.&quot;'>
	<id>tag:youtube.com,2008:channels</id>
	<updated>2015-02-16T19:14:12.656Z</updated>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://gdata.youtube.com/schemas/2007#channel'/>
	<title>Channels matching: webauditors</title>
	<logo>http://www.gstatic.com/youtube/img/logo.png</logo>
	<link rel='http://schemas.google.com/g/2006#spellcorrection' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/channels?q=web+auditors&amp;start-index=1&amp;max-results=1&amp;oi=spell&amp;spell=1&amp;v=2' title='web auditors'/>
	<link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/channels?v=2'/>
	<link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/channels/batch?v=2'/>
	<link rel='self' type='application/atom+xml' href='https://gdata.youtube.com/feeds/api/channels?q=webauditors&amp;start-index=1&amp;max-results=1&amp;v=2'/>
	<link rel='service' type='application/atomsvc+xml' href='https://gdata.youtube.com/feeds/api/channels?alt=atom-service&amp;v=2'/>
	//<link rel='next' type='application/atom+xml' href='https://api.tubefixer.ovh/feeds/api/channels?q=webauditors&amp;start-index=2&amp;max-results=1&amp;v=2'/>
	<author>
		<name>YouTube</name>
		<uri>http://www.youtube.com/</uri>
	</author>
	<generator version='2.1' uri='http://gdata.youtube.com'>YouTube data API</generator>
	<openSearch:totalResults>1</openSearch:totalResults>
	<openSearch:startIndex>1</openSearch:startIndex>
	<openSearch:itemsPerPage>1</openSearch:itemsPerPage>
    $entries
</feed>
<debug>
$response
</debug>
XML;
die($youtubeXML);
}
else{
	
die("An internal server error has occured! If there is a new version of the server please update to the latest version! Error: " . $response);
}
curl_close($curlConnectionInitialization);	
}
respondEmpty();

function getDescription($videoId){
	$decodeResponce['items'][0]['snippet']['description'];
} 
function respondEmpty(){
	$youtubeXML = <<<sting
<br>Error: client request api v2!!!<br/>
sting;
die($youtubeXML);
}