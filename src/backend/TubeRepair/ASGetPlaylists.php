<?php 
include "configuration.php";
if(isset($_GET["channelId"])){
$curlConnectionInitialization = curl_init("https://" . $APIurl . "/youtube/v3/playlists?part=snippet&maxResults=" . $MaxCount . "&channelId=" . $_GET["channelId"] ."&type=video&type=channel&order=relevance&key=" . $APIkey);
curl_setopt($curlConnectionInitialization, CURLOPT_HEADER, 0);
curl_setopt($curlConnectionInitialization, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($curlConnectionInitialization);
if(curl_error($curlConnectionInitialization)) {
  exit;
}
$decodeResponce = json_decode($response, true);
$kindResponse = json_decode($response, false)->kind;
if($kindResponse == "youtube#playlistListResponse"){
	$totalResults = $decodeResponce['pageInfo']['totalResults'];
	$PageResults = $decodeResponce['pageInfo']['resultsPerPage'];
	$maxResultsFromYT = $totalResults;
	if($totalResults > $PageResults){$maxResultsFromYT = $PageResults;}
	$entries = "";
	for($i = 1; $i<$maxResultsFromYT; $i++){
	//	echo $response;
	$PlaylistID = $decodeResponce['items'][$i]['id'];
	$channelname = $decodeResponce['items'][$i]['snippet']['channelTitle'];
	//$description = $decodeResponce['items'][$i]['snippet']['description'];
	$playlistname = $decodeResponce['items'][$i]['snippet']['title'];
	$publishDate = 	rtrim($decodeResponce['items'][$i]['snippet']['publishedAt'], 'Z') . ".000Z";
	$channelId = $decodeResponce['items'][$i]['snippet']['channelId'];
	//$etag = $decodeResponce['items'][$i]['etag'];
	$defaultTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['default']['url'];
	$mediumTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['medium']['url'];
	$highTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['high']['url'];
	$entry = <<<Entry
<entry>
		<id>http://$baseURL/feeds/api/users/$channelId/playlists/$PlaylistID</id>
		<published>$publishDate</published>
		<updated>$publishDate</updated>
		<category scheme='http://schemas.google.com/g/2005#kind' term='http://$baseURL/schemas/2007#playlistLink'/>
		<title type='text'>$playlistname</title>
		<content type='text'/>
		<link rel='related' type='application/atom+xml' href='http://$baseURL/feeds/api/users/$channelId'/>
		<link rel='alternate' type='text/html' href='http://www.youtube.com/view_play_list?p=$PlaylistID'/>
		<link rel='self' type='application/atom+xml' href='http://$baseURL/feeds/api/users/$channelId/playlists/$PlaylistID'/>
		<author>
			<name>$channelname</name>
			<uri>http://$baseURL/feeds/api/users/$channelId</uri>
		</author>
		<yt:description/>
		<gd:feedLink rel='http://$baseURL/schemas/2007#playlist' href='http://$baseURL/feeds/api/playlists/$PlaylistID' countHint='23'/>
		<media:group>
			<media:thumbnail url='$defaultTHURL' height='90' width='120' yt:name='default'/>
			<media:thumbnail url='$highTHURL' height='360' width='480' yt:name='hqdefault'/>
			<yt:duration seconds='0'/>
		</media:group>
		<yt:playlistId>$PlaylistID</yt:playlistId>
	</entry>
Entry;
   $entries = $entries . $entry;
	}
$youtubeXML = <<<XML
<?xml version='1.0' encoding='UTF-8'?>
<feed
	xmlns='http://www.w3.org/2005/Atom'
	xmlns:media='http://search.yahoo.com/mrss/'
	xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/'
	xmlns:gd='http://schemas.google.com/g/2005'
	xmlns:yt='http://$baseURL/schemas/2007'>
	<id>http://$baseURL/feeds/api/users/10fabronaldo7/playlists</id>
	<updated>2012-01-02T17:18:56.845Z</updated>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://$baseURL/schemas/2007#playlistLink'/>
	<title type='text'>Playlists of 10fabronaldo7</title>
	<logo>http://www.youtube.com/img/pic_youtubelogo_123x63.gif</logo>
	<link rel='related' type='application/atom+xml' href='http://$baseURL/feeds/api/users/10fabronaldo7'/>
	<link rel='alternate' type='text/html' href='http://www.youtube.com/profile?user=10fabronaldo7#p/p'/>
	<link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://$baseURL/feeds/api/users/10fabronaldo7/playlists'/>
	<link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='http://$baseURL/feeds/api/users/10fabronaldo7/playlists/batch'/>
	<link rel='self' type='application/atom+xml' href='http://$baseURL/feeds/api/users/10fabronaldo7/playlists?start-index=1&amp;max-results=25'/>
	<author>
		<name>10fabronaldo7</name>
		<uri>http://$baseURL/feeds/api/users/10fabronaldo7</uri>
	</author>
	<generator version='2.1' uri='http://$baseURL'>YouTube data API</generator>
	<openSearch:totalResults>6</openSearch:totalResults>
	<openSearch:startIndex>1</openSearch:startIndex>
	<openSearch:itemsPerPage>25</openSearch:itemsPerPage>
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