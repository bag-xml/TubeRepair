<?php

function fetchImage($url) {
    return file_get_contents($url);
}

function createImageFromAny($data) {
    $image = @imagecreatefromstring($data);
    if (!$image) {
        throw new Exception('Unsupported image type or download failed.');
    }
    return $image;
}

function resizeImageToFit($src, $targetWidth, $targetHeight, $paddingTop, $paddingBottom, $paddingLeft, $paddingRight, $backgroundColor = [0, 0, 0]) {
    // Adjust target dimensions to account for padding
    $adjustedWidth = $targetWidth - ($paddingLeft + $paddingRight);
    $adjustedHeight = $targetHeight - ($paddingTop + $paddingBottom);

    $dst = imagecreatetruecolor($targetWidth, $targetHeight);

    $bgColor = imagecolorallocate($dst, $backgroundColor[0], $backgroundColor[1], $backgroundColor[2]);
    imagefill($dst, 0, 0, $bgColor);

    $startX = $paddingLeft;
    $startY = $paddingTop;

    imagecopyresampled($dst, $src, $startX, $startY, 0, 0, $adjustedWidth, $adjustedHeight, imagesx($src), imagesy($src));

    return $dst;
}


if (isset($_GET['ThumbnailURL'])) {
    $imageUrl = filter_var($_GET['ThumbnailURL'], FILTER_SANITIZE_URL);
    $imageUrl = urldecode($imageUrl);

    // Target output size
    $width = 780;
    $height = 660;

    try {
        $imageData = fetchImage($imageUrl);
        if (!$imageData) {
            throw new Exception('Image download failed.');
        }

        $src = createImageFromAny($imageData);

        $dst = resizeImageToFit($src, $width, $height, 185, 182, 37, 34);

        header('Content-Type: image/jpeg');
        imagejpeg($dst);

        imagedestroy($src);
        imagedestroy($dst);
    } catch (Exception $e) {
        header('HTTP/1.1 400 Bad Request');
        echo "Error: " . $e->getMessage();
    }
} else {
    header('HTTP/1.1 400 Bad Request');
    echo "Missing ThumbnailURL parameter";
}
