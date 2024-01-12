<?php 
include "configuration.php";
if(isset($_GET["max-results"])){
if(isset($_SERVER['HTTP_X_TUBEREPAIR_API_KEY'])){ $APIkey = $_SERVER['HTTP_X_TUBEREPAIR_API_KEY'];}else{exit;}
$curlConnectionInitialization = curl_init("https://" . $APIurl . "/youtube/v3/videos?part=snippet&chart=mostPopular&maxResults=" . $MaxCount . "&type=video&key=" . $APIkey);
curl_setopt($curlConnectionInitialization, CURLOPT_HEADER, 0);
curl_setopt($curlConnectionInitialization, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($curlConnectionInitialization);
if(curl_error($curlConnectionInitialization)) {
  die(curl_error($curlConnectionInitialization));
}
$decodeResponce = json_decode($response, true);
$kindResponse = json_decode($response, false)->kind;
if($kindResponse == "youtube#videoListResponse"){
	$maxResultsFromYT = $decodeResponce['pageInfo']['resultsPerPage'];
	$entries = "";
	for($i = 0; $i<$maxResultsFromYT; $i++){
	$videoID = $decodeResponce['items'][$i]['id'];
	$channelname = $decodeResponce['items'][$i]['snippet']['channelTitle'];
	$description = "Not Supported!";
	//$description = $decodeResponce['items'][$i]['snippet']['description'];
	$videoname = $decodeResponce['items'][$i]['snippet']['title'];
	$publishDate = $decodeResponce['items'][$i]['snippet']['publishedAt'];
	$channelId = $decodeResponce['items'][$i]['snippet']['channelId'];
	$etag = $decodeResponce['items'][$i]['etag'];
	$defaultTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['default']['url'];
	$mediumTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['medium']['url'];
	$highTHURL = $decodeResponce['items'][$i]['snippet']['thumbnails']['high']['url'];
	$entryiOS = <<<Entry
	<entry gd:etag="$etag">
    <id>aefdhdajada</id>
    <published>$publishDate</published>
    <updated>$publishDate</updated>
    <category scheme="http://schemas.google.com/g/2005#kind" term="http://$baseURL/schemas/2007#video" />
    <category scheme="http://$baseURL/schemas/2007/categories.cat" term="Music" label="Music" />
    <title>$videoname</title>
    <content type="video/mp4" src="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" />
    <link rel="alternate" type="text/html" href="http://www.youtube.com/watch?v=$videoID&amp;feature=youtube_gdata" />
    <link rel="http://$baseURL/schemas/2007#video.complaints" type="application/atom+xml" href="http://api.tubefixer.ovh/feeds/api/videos/$videoID/complaints" />
    <link rel="http://$baseURL/schemas/2007#video.related" type="application/atom+xml" href="http://api.tubefixer.ovh/feeds/api/videos/$videoID/related" />
    <link rel="http://$baseURL/schemas/2007#video.captionTracks" type="application/atom+xml" href="http://api.tubefixer.ovh/feeds/api/videos/$videoID/captions" yt:hasEntries="false" />
    <link rel="http://$baseURL/schemas/2007#mobile" type="text/html" href="http://m.youtube.com/details?v=$videoID" />
    <link rel="http://$baseURL/schemas/2007#uploader" type="application/atom+xml" href="http://api.tubefixer.ovh/feeds/api/users/UCealgY8FrRPdAaCN8UtkuIQ" />
    <link rel="self" type="application/atom+xml" href="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" />
    <author>
      <name>$channelname</name>
      <uri>http://www.google.com/feeds/api/users/$channelname</uri>
      <yt:userId>$channelId</yt:userId>
    </author>

    <yt:accessControl action="comment" permission="allowed" />
    <yt:accessControl action="commentVote" permission="allowed" />
    <yt:accessControl action="videoRespond" permission="denied" />
    <yt:accessControl action="rate" permission="allowed" />
    <yt:accessControl action="embed" permission="allowed" />
    <yt:accessControl action="list" permission="allowed" />
    <yt:accessControl action="monetize" permission="denied" />
    <yt:accessControl action="autoPlay" permission="allowed" />
    <yt:accessControl action="syndicate" permission="allowed" />
    <gd:comments><gd:feedLink href='http://www.google.com/feeds/comments'/></gd:comments>
    <yt:statistics favoriteCount="0" viewCount="0" />
<gd:rating average="3" max="3" min="3" numRaters="1" rel="http://schemas.google.com/g/2005#overall" />
    <yt:rating numDislikes="0" numLikes="0" />
<yt:hd />
    <media:group>
      <media:category label="Music" scheme="http://$baseURL/schemas/2007/categories.cat">Music</media:category>
      <media:content url="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" type="video/mp4" medium="video" isDefault="true" expression="full" duration="0" yt:format="3" />
      <media:content url="http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp" medium="video" expression="full" duration="0" yt:format="2" />
      <media:content url="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" type="video/mp4" medium="video" expression="full" duration="0" yt:format="8" />
      <media:content url="http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp" medium="video" expression="full" duration="0" yt:format="9" />
      <media:credit role="uploader" scheme="urn:youtube" yt:display="$channelname">$channelname</media:credit>
      <media:description type="plain">$description</media:description>
      <media:keywords>keywords</media:keywords>
      <media:license type="text/html" href="http://www.youtube.com/t/terms">youtube</media:license>
      <media:player url="http://www.youtube.com/watch?v=$videoID&amp;feature=youtube_gdata_player" />
      <media:thumbnail url="$defaultTHURL" height="90" width="120" yt:name="default" />
			<media:thumbnail url="$mediumTHURL" height="180" width="320" yt:name="mqdefault" />
      <media:thumbnail url="$highTHURL" height="360" width="480" yt:name="hqdefault" />
      <media:thumbnail url="$highTHURL" height="480" width="640" yt:name="sddefault" />
      <media:thumbnail url="$highTHURL" height="720" width="1280" yt:name="naxresdefault" />
      <media:title type="plain">$videoname</media:title>
      <yt:aspectRatio>widescreen</yt:aspectRatio>
      <yt:duration seconds="0" />
      <yt:uploaded>$publishDate</yt:uploaded>
      <yt:uploaderId>$channelId</yt:uploaderId>
      <yt:videoid>$videoID</yt:videoid>
    </media:group>
  </entry>
Entry;
   $entryAndroid = <<<entry
	<entry>
		<id>http://$baseURL/feeds/api/videos/$videoID</id>
		<youTubeId id='$videoID'>$videoID</youTubeId>
		<published>$publishDate</published>
		<updated>$publishDate</updated>
		<category scheme="http://gdata.youtube.com/schemas/2007/categories.cat" label="Howto &amp; Style" term="Howto &amp; Style">Howto &amp; Style</category>
		<title type='text'>$videoname</title>
		<content type='text'>$description</content>
		<link rel="http://gdata.youtube.com/schemas/2007#video.related" href="http://$baseURL/TubeRepair/feeds/api/videos/$videoID/related"/>
		<author>
			<name>$channelTitle</name>
			<uri>http://gdata.youtube.com/feeds/api/users/$channelTitle</uri>
		</author>
		<gd:comments>
			<gd:feedLink href='http://$baseURL/feeds/api/videos/$videoID/comments' countHint='0'/>
		</gd:comments>
		<media:group>
			<media:category label='Howto &amp; Style' scheme='http://gdata.youtube.com/schemas/2007/categories.cat'></media:category>
			<media:content url='http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID' type='video/3gpp' medium='video' expression='full' duration='999' yt:format='3'/>
			<media:description type='plain'>$description</media:description>
			<media:keywords></media:keywords>
			<media:player url='http://www.youtube.com/watch?v=$videoID'/>
			<media:thumbnail yt:name='hqdefault' url='$defaultTHURL' height='240' width='320' time='00:00:00'/>
			<media:thumbnail yt:name='poster' url='$mediumTHURL' height='240' width='320' time='00:00:00'/>
			<media:thumbnail yt:name='default' url='$highTHURL' height='240' width='320' time='00:00:00'/>
			<yt:duration seconds='100'/>
			<yt:videoid id='-CH-Kx2sl9c'>-CH-Kx2sl9c</yt:videoid>
			<youTubeId id='-CH-Kx2sl9c'>-CH-Kx2sl9c</youTubeId>
			<media:credit role='uploader' name='$channelTitle'>$channelTitle</media:credit>
		</media:group>
		<gd:rating average='0' max='0' min='0' numRaters='0' rel='http://schemas.google.com/g/2005#overall'/>
		<yt:statistics favoriteCount="0" viewCount="0"/>
		<yt:rating numLikes="0" numDislikes="0"/>
	</entry>
entry;
if(str_contains($_SERVER["HTTP_USER_AGENT"], "Android")){$entries = $entries . $entryAndroid;}else{$entries = $entries . $entryiOS;}
	}
$youtubeXML = <<<XML
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'
xmlns:media='http://search.yahoo.com/mrss/'
xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/'
xmlns:gd='http://schemas.google.com/g/2005'
xmlns:yt='http://gdata.youtube.com/schemas/2007'>
    <id>http://gdata.youtube.com/feeds/api/standardfeeds/us/recently_featured</id>
    <updated>2010-12-21T18:59:58.000-08:00</updated>
    <category scheme='http://schemas.google.com/g/2005#kind' term='http://gdata.youtube.com/schemas/2007#video'/>
    <title type='text'> </title>
    <logo>http://www.youtube.com/img/pic_youtubelogo_123x63.gif</logo>
    <author>
        <name>YouTube</name>
        <uri>http://www.youtube.com/</uri>
    </author>
    <generator version='2.0' uri='http://gdata.youtube.com/'>YouTube data API</generator>
    <openSearch:totalResults>10</openSearch:totalResults>
    <openSearch:startIndex>1</openSearch:startIndex>
    <openSearch:itemsPerPage>10</openSearch:itemsPerPage>
  $entries
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