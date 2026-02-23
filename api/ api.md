# Home Moduel

## banners
轮播图

```
url: "/recommend/banner"
method: GET
reponse file: ./recommend_banner.json
```

## Recommendation Playlists

推荐歌单

```
url: "/recommend/daily"
header: {
    "Cookie": "cookie-value"
}
method: GET
reponse file: ./recommend_daily.json
```

```
url: "/recommend/playlist"
method: GET
reponse file: ./recommend_playlist.json
```

## Recommendation Songs

新歌推荐

```
url: "/recommend/new/songs?type=6" 
method: GET
reponse file: ./recommend_new_songs.json
```

> type (default: 5) 1: 内地, 2: 欧美, 3: 日本, 4: 韩国, 5: 最新, 6: 港台

## Recommendation Albums

新专辑推荐

```
url: "/recommend/new/albums?type=6"
method: GET
reponse file: ./recommend_new_albums.json
```

> type (default: 1) 1：内地，2：港台，3：欧美，4：韩国，5：日本，6：其他


# Playlist Moduel

歌单

## Category

```
url: "/playlist/category"
method: GET
reponse file: ./playlist_category.json
```

## Category List

歌单分类列表

```
url: "/playlist/information?number=1&size=20&sort=2&id=10000000"
method: GET
reponse file: ./playlist_information.json
```

> sort // 2 最新，5,推荐, default 5

> id // /playlist/category 接口返回的id, default 10000000



## Playlist Detail

歌单详情

```
url: "/playlist/detail?dissid=7708704368"
method: GET
reponse file: ./playlist_detail.json
```
> dissid 使用 /playlist/information 返回的列表中的 dissid

# Singer Module

歌手

## Filter 

返回歌手筛选条件
```
url: "/artist/category"
method: GET
reponse file: ./singer_filter.json
```

## List

返回筛选条件下的歌手列表

```
url: "/artist/list?area=-100&sex=-100&genre=-100&index=-100&page=1&size=80"
method: GET
reponse file: ./singer_filter_list.json
```
> 参数值 来源 /artist/category 接口返回

## Singer Detail with Songs

返回歌手详情和每一页的歌曲

```
url: "/artist/detail?id=0025NhlN2yWrP4&page=1"
method: GET
reponse file: ./singer_detail.json
```
> id来源于 /artist/list?area=-100&sex=-100&genre=-100&index=-100&page=1&size=80 的 singer_mid


## Singer Albums list

返回歌手专辑列表信息

```
url: "/artist/albums?id=0025NhlN2yWrP4&page=1&size=20"
method: GET
reponse file: ./singer_albums.json
```

> id来源于 /artist/list?area=-100&sex=-100&genre=-100&index=-100&page=1&size=80 的 singer_mid 

## Singer MV list

返回歌手MV列表信息

```
url: "/artist/mvs?id=0025NhlN2yWrP4&page=1&size=20"
method: GET
reponse file: ./singer_mvs.json
```

> id来源于 /artist/list?area=-100&sex=-100&genre=-100&index=-100&page=1&size=80 的 singer_mid


## Singer Songs list

返回歌手歌曲列表信息

```
url: "/artist/songs?id=0025NhlN2yWrP4&page=1&size=20"
method: GET
reponse file: ./singer_songs.json
```

> id来源于 /artist/list?area=-100&sex=-100&genre=-100&index=-100&page=1&size=80 的 singer_mid

# Ranking Module

排行榜

## Category with list

返回榜单主分类以及子分类和每个自分类前三首歌曲

```
url: "/rankings/list"
method: GET
reponse file: ./ranking_list.json
```

##  Detail

返回每一个榜单分类的详情

```
url: "/rankings/detail?id=62&page=1&size=100&period=2026-02-12"
method: GET
reponse file: ./ranking_detail.json
```

> id 是 /rankings/list 返回每一个列表的 topID, period是列表的period


# Radio Module

电台

## Caegory List

返回电台分类列表

```
url: "/radio/category"
method: GET
reponse file: ./radio_list.json
```

## Detail

返回电台下的歌曲列表, 第二次请求会返回不同的歌曲信息，

```
url: "/radio/songlist?id=101"
method: GET
reponse file: ./radio_songs.json
```

> id是/radio/category 列表中的id 

# MV Module

MV

## Caegory

MV分类

```
url: "/mv/category"
method: GET
reponse file: ./mv_category.json
```

## List

MV分类下的列表

```
url: "/mv/list?area=15&version=7&page=1&size=10"
method: GET
reponse file: ./mv_category_list.json
```

> 参数来自于 /mv/category 返回

## Detail

MV详情

```
url: "/mv/detail?id=d0032k98yoy"
method: GET
reponse file: ./mv_detail.json
```
> id 来自 /mv/list?area=15&version=7&page=1&size=10 列表中的vid


# Album Module

专辑

## Album Detail

专辑详情

```
url: "/album/detail?id=004Bux530GytNj"
method: GET
reponse file: ./album_detail.json
```

> id 是 专辑 mid 

## Album Songs

专辑下的歌曲

```
url: "/album/songs?id=004Bux530GytNj"
method: GET
reponse file: ./album_songs.json
```

> id 是 专辑 mid 

# Song Module

歌曲

## Song Detail

歌曲详情

```
url: "/song/detail?id=003FYnmA2KmMXg"
method: GET
reponse file: ./song_detail.json
```

## Song Url

歌曲播放链接

可以获取到播放链接的
```
url: /song/url?id=000RUod52SSa9F
method: GET
Header[Cookie]= "Cookie Value" // 后台配置， API Config页面 
response:
{
    "code": 1,
    "message": "Success",
    "data": {
        "url": "https://dl.stream.qqmusic.qq.com/C400000RUod52SSa9F.m4a?guid=8117976891&vkey=4D9DAE4BF660EDC0DCF4ED6A2A51DBD02849EC5587CD977246A5FA43B4CD571516EDEB416921CE437CE6F722496104E107A33F43A1392850__v21519284e&uin=934247610&fromtag=120032",
        "songmid": "000RUod52SSa9F",
        "vkey": "4D9DAE4BF660EDC0DCF4ED6A2A51DBD02849EC5587CD977246A5FA43B4CD571516EDEB416921CE437CE6F722496104E107A33F43A1392850__v21519284e",
        "filename": "C400000RUod52SSa9F.m4a",
        "source": "purl"
    }
}

```
获取播放链接失败的
```
url: /song/url?id=00061J2t0b0PPW
method: GET
Header[Cookie]= "Cookie Value" // 后台配置， API Config页面 
response:
{
    "code": 0,
    "message": "VIP-only content or not available in your region",
    "data": []
}

```

返回 code 为0时，
第一步 需要拼接 API Fallback URL + '?types=search&source=joox&name={$songName}' 来获取查询到歌曲信息
```
[
    {
        "id": "xxxx",
        "name": "",
        "artist": [],
        "album": "",
        "pic_id":"",
        "url_id":"",
        "lyric_id":"",
        "source":"joox",
        "from":"xx"
    },
    {}
]
```
第二步，从上一步匹配到 歌曲信息中获取到 id ，然后请求 API Fallback URL + '?types=url&source=joox&id={$id}' 来获取查询到歌曲播放链接
```
{
    "url":"",
    "br": 320,
    "size": 9076031,
    "from":"xx"
}
```
第三步，上一步返回 url依旧为空，需要提示用户暂无播放权限就行

# Search Module

搜索模块

## Hot Key

返回热搜词

```
url: "/search/hotkey"
method: GET
reponse file: ./search_hot_key.json
```

## Search Song

返回 搜索的歌曲列表

```
url: "/search/?keyword=周杰伦&type=0&page=1&size=20"
method: GET
reponse file: ./search_song.json
```

## Search Contains Singer

返回 包含搜索的歌手列表

```
url: "/search/?keyword=周杰伦&type=9&page=1&size=20"
method: GET
reponse file: ./search_singer.json
```

## Search Albums

返回 搜索的专辑列表

```
url: "/search/?keyword=周杰伦&type=8&page=1&size=20"
method: GET
reponse file: ./search_albums.json
```

## Search MV

返回 搜索的MV列表

```
url: "/search/?keyword=周杰伦&type=12&page=1&size=20"
method: GET
reponse file: ./search_mv.json
```

# Lyric Module

返回 歌词以及歌词翻译

```
url: "/search/?keyword=周杰伦&type=12&page=1&size=20"
method: GET
reponse file: ./lyric.json
```

