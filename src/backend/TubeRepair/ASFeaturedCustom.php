<?php
include "configuration.php";

if(isset($_SERVER['HTTP_OAUTH_TOKEN'])) {
	
    $oauthToken = $_SERVER['HTTP_OAUTH_TOKEN'];
    $command = 'python3 fetch_videos.py ' . escapeshellarg($oauthToken) . ' | python3 parse_videos.py';
    $response = "[" . shell_exec($command) . "]";

    $decodeResponseYTi = json_decode($response, true);

} else {
$queryString = $_SERVER['QUERY_STRING'];
header("Location: http://$baseURL/$serverScriptDirectory/ASFeatured.php?max-results=20&time=today&start-index=1&safeSearch=none&format=2%2C3%2C8%2C9%2C28%2C31%2C32%2C34%2C35%2C36%2C38", true, 301);
}

if(str_contains($_SERVER["HTTP_USER_AGENT"], "com.google.ios.youtube/1.0") ||str_contains($_SERVER["HTTP_USER_AGENT"], "com.google.ios.youtube/1.1")|| str_contains($_SERVER["HTTP_USER_AGENT"], "com.google.ios.youtube/1.2") || str_contains($_SERVER["HTTP_USER_AGENT"], "Android") || 1==1 ){
	$maxResultsFromYT = 0;
	$entries = "";
	foreach($decodeResponseYTi as $decodeResponse){
	$videoID = $decodeResponse['videoId'];
	$channelname = $decodeResponse['uploader'];
	$description = str_replace(['&', '<', '>'], ['&amp;', '&lt;', '&gt;'], $decodeResponse['description']);
	//$description = $decodeResponse['items'][0]['snippet']['description'];
	$videoname = $decodeResponse['title'];
	$publishDate = gmdate("Y-m-d\TH:i:s.000\Z", strtotime($decodeResponse['publishDate']));
	$directmediaURL = $decodeResponse['direct_video_url'];
	
	$likes = 10;
	$views = 0;
	$commentCount = 0;
	$favoriteCount = 0;
	$dislikes = 0;
	
	$views = $decodeResponse['view_count'];
	if(isset($decodeResponse['items'][0]['statistics']['likeCount']))
	$likes = $decodeResponse['items'][0]['statistics']['likeCount'];
    if(isset($decodeResponse['items'][0]['statistics']['commentCount']))
	$commentCount = $decodeResponse['items'][0]['statistics']['commentCount'];
    if(isset($decodeResponse['items'][0]['statistics']['favoriteCount']))
	$favoriteCount = $decodeResponse['items'][0]['statistics']['favoriteCount'];
    if(isset($decodeResponse['items'][0]['statistics']['likeCount']) && isset($decodeResponse['items'][0]['statistics']['viewCount']))
	$dislikes = ($views - ($likes * 16)) / 48;
    $durationInSeconds = $decodeResponse['duration'];
	
	$channelId = $decodeResponse['channelId'];
	$etag = $decodeResponse['etag'];
	$defaultTHURL = $decodeResponse['thumbnail_url'];
	$fullThumbnailURL = "http://" . $baseURL . "/" . $serverScriptDirectory . "/ASThumbnailResize.php?ThumbnailURL=" . urlencode($defaultTHURL);

	$entryiOS = <<<Entry
	<entry gd:etag='W/&quot;YDwqeyM.&quot;'>
		<id>tag:youtube.com,2008:playlist:$videoID:$videoID</id>
		<published>$publishDate</published>
		<updated>$publishDate</updated>
		<category scheme='http://schemas.google.com/g/2005#kind' term='http://$baseURL/schemas/1970#video'/>
		<category scheme='http://$baseURL/schemas/1970/categories.cat' term='Howto' label='Howto &amp; Style'/>
		<title>$videoname</title>
		<content type='application/x-shockwave-flash' src='http://www.youtube.com/v/$videoID?version=3&amp;f=playlists&amp;app=youtube_gdata'/>
		<link rel='alternate' type='text/html' href='http://www.youtube.com/watch?v=$videoID&amp;feature=youtube_gdata'/>
		<link rel='http://$baseURL/schemas/1970#video.related' type='application/atom+xml' href='http://$baseURL/feeds/api/videos/$videoID/related?v=2'/>
		<link rel='http://$baseURL/schemas/1970#mobile' type='text/html' href='http://m.youtube.com/details?v=$videoID'/>
		<link rel='http://$baseURL/schemas/1970#uploader' type='application/atom+xml' href='http://$baseURL/feeds/api/users/$channelId?v=2'/>
		<link rel="http://$baseURL/schemas/2007#related" type="application/atom+xml" href="http://api.tubefixer.ovh/feeds/api/videos/$videoID/related" />
		<link rel='related' type='application/atom+xml' href='http://$baseURL/feeds/api/videos/$videoID?v=2'/>
		<link rel='self' type='application/atom+xml' href='http://$baseURL/feeds/api/playlists/8E2186857EE27746/PLyl9mKRbpNIpJC5B8qpcgKX8v8NI62Jho?v=2'/>
		<author>
			<name>$channelname</name>
			<uri>http://$baseURL/feeds/api/users/$channelId</uri>
			<yt:userId>$channelId</yt:userId>
		</author>
		<yt:accessControl action='comment' permission='allowed'/>
		<yt:accessControl action='commentVote' permission='allowed'/>
		<yt:accessControl action='videoRespond' permission='moderated'/>
		<yt:accessControl action='rate' permission='allowed'/>
		<yt:accessControl action='embed' permission='allowed'/>
		<yt:accessControl action='list' permission='allowed'/>
		<yt:accessControl action='autoPlay' permission='allowed'/>
		<yt:accessControl action='syndicate' permission='allowed'/>
		<gd:comments>
			<gd:feedLink rel='http://$baseURL/schemas/1970#comments' href='http://$baseURL/feeds/api/videos/$videoID/comments?v=2' countHint='5'/>
		</gd:comments>
		<yt:location>Paris ,FR</yt:location>
		<media:group>
			<media:category label='Howto &amp; Style' scheme='http://$baseURL/schemas/1970/categories.cat'>Howto</media:category>
			<media:content url='http://www.youtube.com/v/$videoID?version=3&amp;f=playlists&amp;app=youtube_gdata' type='application/x-shockwave-flash' medium='video' isDefault='true' expression='full' duration='0' yt:format='5'/>
			<media:content url='http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp' type='video/3gpp' medium='video' expression='full' duration='0' yt:format='1'/>
			<media:content url='http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp' type='video/3gpp' medium='video' expression='full' duration='0' yt:format='6'/>
			<media:credit role='uploader' scheme='urn:youtube' yt:display='$channelname' yt:type='partner'>$channelId</media:credit>
			<media:description type='plain'>$description</media:description>
			<media:keywords/>
			<media:license type='text/html' href='http://www.youtube.com/t/terms'>youtube</media:license>
			<media:player url='http://www.youtube.com/watch?v=$videoID&amp;feature=youtube_gdata_player'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' time='00:00:00.000' yt:name='default'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' yt:name='mqdefault'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' yt:name='hqdefault'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' time='00:00:00.000' yt:name='start'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' time='00:00:00.000' yt:name='middle'/>
			<media:thumbnail url='$fullThumbnailURL' height='360' width='480' time='00:00:00.000' yt:name='end'/>
			<media:content url="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" type="video/mp4" medium="video" isDefault="true" expression="full" duration="0" yt:format="3" />
            <media:content url="http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp" medium="video" expression="full" duration="0" yt:format="2" />
            <media:content url="http://$baseURL/$serverScriptDirectory/GetVideo.php?videoId=$videoID" type="video/mp4" medium="video" expression="full" duration="0" yt:format="8" />
            <media:content url="http://$baseURL/$serverScriptDirectory/$videoID.3gpp" type="video/3gpp" medium="video" expression="full" duration="0" yt:format="9" />
			<media:title type='plain'>$videoname</media:title>
			<yt:duration seconds='$durationInSeconds'/>
			<yt:uploaded>$publishDate</yt:uploaded>
			<yt:uploaderId>$channelId</yt:uploaderId>
			<yt:videoid>$videoID</yt:videoid>
		</media:group>
		<gd:rating average='0' max='0' min='0' numRaters='0' rel='http://schemas.google.com/g/2005#overall'/>
		<yt:recorded>1970-08-22</yt:recorded>
		<yt:statistics favoriteCount='$favoriteCount' viewCount='$views'/>
		<yt:rating numDislikes='$dislikes' numLikes='$likes'/>
		<yt:position>1</yt:position>
	</entry>
Entry;
$entries = $entries . $entryiOS;
	}
$youtubeXML = <<<XML
<?xml version='1.0' encoding='UTF-8'?>
<feed
	xmlns='http://www.w3.org/2005/Atom'
	xmlns:media='http://search.yahoo.com/mrss/'
	xmlns:openSearch='http://a9.com/-/spec/opensearch/1.1/'
	xmlns:gd='http://schemas.google.com/g/2005'
	xmlns:yt='http://$baseURL/schemas/1970' gd:etag='W/&quot;D0UHSX47eCp7I2A9WhJWF08.&quot;'>
	<id>tag:youtube.com,2008:playlist:8E2186857EE27746</id>
	<updated>2012-08-23T12:33:58.000Z</updated>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://$baseURL/schemas/1970#playlist'/>
	<title></title>
	<subtitle></subtitle>
	<logo>http://www.gstatic.com/youtube/img/logo.png</logo>
	<link rel='alternate' type='text/html' href='http://www.youtube.com/playlist?list=PL8E2186857EE27746'/>
	<link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://$baseURL/feeds/api/playlists/8E2186857EE27746?v=2'/>
	<link rel='http://schemas.google.com/g/2005#batch' type='application/atom+xml' href='http://$baseURL/feeds/api/playlists/8E2186857EE27746/batch?v=2'/>
	<link rel='self' type='application/atom+xml' href='http://$baseURL/feeds/api/playlists/8E2186857EE27746?start-index=1&amp;max-results=25&amp;v=2'/>
	<link rel='service' type='application/atomsvc+xml' href='http://$baseURL/feeds/api/playlists/8E2186857EE27746?alt=atom-service&amp;v=2'/>
	<author>
		<name>$channelname</name>
		<uri>http://$baseURL/feeds/api/users/$channelId</uri>
		<yt:userId>$channelId</yt:userId>
	</author>
	<generator version='2.1' uri='http://$baseURL'>YouTube data API</generator>
<openSearch:totalResults>$maxResultsFromYT</openSearch:totalResults>
  <openSearch:itemsPerPage>$maxResultsFromYT</openSearch:itemsPerPage>
  <openSearch:startIndex>1</openSearch:startIndex>
  $entries
</feed>
XML;
die($youtubeXML);
}

curl_close($curlConnectionInitialization);	
?>

