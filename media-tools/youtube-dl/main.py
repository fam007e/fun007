from pytube import YouTube

def Download(link):
    youtubeObject = YouTube(link)
    youtubeObject = youtubeObject.streams.get_highest_resolution()
    try:
        youtubeObject.download()
    except:
        print("There has been an error in downloading your youtube video")
    print("The download has completed!")

link = input("Insert the youtube video URL here:")
Download(link)