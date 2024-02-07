import json
import sys
import re

def find_direct_video_url(data):
    url_pattern = r'https:\/\/[a-zA-Z0-9\-]+\.googlevideo\.com\/'
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, str) and re.search(url_pattern, value):
                return value
            else:
                found_url = find_direct_video_url(value)
                if found_url:
                    return found_url
    elif isinstance(data, list):
        for item in data:
            found_url = find_direct_video_url(item)
            if found_url:
                return found_url
    return None

def convert_duration_to_seconds(duration_str):
    parts = duration_str.split(':')
    seconds = 0
    multiplier = 1
    while parts:
        try:
            seconds += multiplier * int(parts.pop())
            multiplier *= 60
        except ValueError:
            return 0
    return seconds

def extract_video_details(data):
    videos = []
    try:
        items_path = ['contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'richGridRenderer', 'contents']
        items = data
        for key in items_path:
            if isinstance(key, int):
                items = items[key]
            else:
                items = items.get(key, {})
        
        for item in items:
            if 'richItemRenderer' in item and 'content' in item['richItemRenderer']:
                content = item['richItemRenderer']['content']
                if 'videoRenderer' in content:
                    video = content['videoRenderer']
                    direct_video_url = find_direct_video_url(video)
                    
                    videoId = video['videoId']
                    channelId = video.get('ownerText', {}).get('runs', [{}])[0].get('navigationEndpoint', {}).get('browseEndpoint', {}).get('browseId', '')
                    etag = video.get('trackingParams', '')
                    publishDate = video.get('publishedTimeText', {}).get('simpleText', '')
                    commentCount = int(video.get('commentCount', {}).get('simpleText', '').replace(',', '')) if 'commentCount' in video else 0
                    
                    view_count_text = video.get('viewCountText', {}).get('simpleText', '0').split()[0].replace(',', '')
                    try:
                        view_count = int(view_count_text)
                    except ValueError:
                        view_count = 0

                    duration_str = video.get('lengthText', {}).get('simpleText', '')
                    duration_seconds = convert_duration_to_seconds(duration_str)

                    video_info = {
                        'title': video['title']['runs'][0]['text'] if 'runs' in video['title'] else video['title'].get('simpleText', 'No title available'),
                        'description': video.get('descriptionSnippet', {}).get('runs', [{}])[0].get('text', 'No description available'),
                        'uploader': video['longBylineText']['runs'][-1]['text'],
                        'thumbnail_url': video['thumbnail']['thumbnails'][-1]['url'],
                        'video_url': f"https://www.youtube.com/watch?v={videoId}",
                        'channel_pic_url': video['channelThumbnailSupportedRenderers']['channelThumbnailWithLinkRenderer']['thumbnail']['thumbnails'][0]['url'],
                        'videoId': videoId,
                        'channelId': channelId,
                        'etag': etag,
                        'publishDate': publishDate,
                        'commentCount': commentCount,
                        'view_count': view_count,
                        'duration': duration_seconds,
                        'direct_video_url': direct_video_url if direct_video_url else 'No direct URL available',
                        'like_count': video.get('simpleLikesText', {}).get('simpleText', 'No like count available')
                    }
                    videos.append(video_info)
    except KeyError as e:
        print(f"Error navigating JSON structure: {e}")
    
    return videos

# Read JSON data from stdin
json_data = json.load(sys.stdin)

# Extract video details
videos_info = extract_video_details(json_data)

# Print extracted video details
for i, video in enumerate(videos_info):
    if i < len(videos_info) - 1:
        print(json.dumps(video, indent=4) + ',')
    else:
        print(json.dumps(video, indent=4))
