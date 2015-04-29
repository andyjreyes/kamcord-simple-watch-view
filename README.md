# Watch Kamcord Videos
A simple watch view for Kamcord videos. A personal experiment in asynchronous downloading, video media, and custom views.

Watch Kamcord Videos is a Universal iOS app that quickly gets you to a list of Kamcord videos. Scroll through and tap on any thumbnail to bring up the video! Pull to refresh for even more fun!

##Delighters:

- Asynchronous downloading of thumbnail images makes the app feel fast! This was the most challenging part to get right for me. Lots of experimentation with different downloading and cell refresh strategies.

- Beautiful custom table view cells! Thumbnails take up the full width of the screen with Titles overlaid on top.

- A slight gradient is applied to every cell so the Title is always legible. I love little UI things like that.

- The Kamcord logo is the placeholder thumbnail for all you speedy scrollers out there. Watch as the video thumbnails fade in to place!

- Thumbnails and Titles appear larger or smaller depending on device type!

- Pull-to-Refresh the list multiple times for the most fun you’ve had refreshing a list in an app!

- Videos can be played in Landscape Orientation, even though the app itself prefers Portrait.

- Organized code and liberal use of constants for maximum ~~OCD~~ tweakability!


##Known Bugs:

- While it certainly doesn’t break anything, you can browse the list of videos in Landscape Orientation by closing a video while in Landscape. The first images on screen will have their gradient in the wrong place at first due to the orientation change, but the rest of the images will load their gradients properly.

- The screen-wide thumbnails may cause slowdown on Retina iPads (at least it seemed that way on Simulator, which surprised me).


##Future Plans:

- Make the asynchronous calls to thumbnail images cancelable so we can better use device resources to load thumbnails for cells currently in view.

- Use MPMoviePlayerDidExitFullscreenNotification to correctly orient the app when videos finish while playing in Landscape mode.

- Make the iPad UI a UICollectionView with a grid of my custom WatchViewCells. Maybe have them slide sideways instead of up and down just to change things up.