/*global module, require, Promise, console */

// AWS SDK v3 ships with the nodejs18.x and newer runtimes, so no dependency
// bundle is needed. The v2 aws-sdk package stopped being included in the
// runtime at nodejs16.x, which is why this example was updated with the
// runtime bump.
'use strict';
const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3'),
	fs = require('fs'),
	s3 = new S3Client({}),
	downloadFileFromS3 = function (bucket, fileKey, filePath) {
		console.log('downloading', bucket, fileKey, filePath);
		return s3.send(new GetObjectCommand({Bucket: bucket, Key: fileKey}))
			.then(response => new Promise(function (resolve, reject) {
				const file = fs.createWriteStream(filePath),
					stream = response.Body;
				stream.on('error', reject);
				file.on('error', reject);
				file.on('finish', function () {
					console.log('downloaded', bucket, fileKey);
					resolve(filePath);
				});
				stream.pipe(file);
			}));
	},
	uploadFileToS3 = function (bucket, fileKey, filePath, contentType) {
		console.log('uploading', bucket, fileKey, filePath);
		// Thumbnails are small enough to send in one request. No ACL is set:
		// buckets created since 2023 default to ownership controls that reject
		// any object ACL, including 'private', which made the old upload fail.
		return s3.send(new PutObjectCommand({
			Bucket: bucket,
			Key: fileKey,
			Body: fs.readFileSync(filePath),
			ContentType: contentType
		})).then(() => filePath);
	};

module.exports = {
	downloadFileFromS3: downloadFileFromS3,
	uploadFileToS3: uploadFileToS3
};
