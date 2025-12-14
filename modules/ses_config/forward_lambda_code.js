'use strict';

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

// 📢 ఇక్కడ మీ వ్యక్తిగత ఇమెయిల్ ID ని ఉంచబడింది.
const FORWARDING_EMAIL = "sreekanthpaleti1999@gmail.com"; 

exports.handler = async (event) => {
    console.log("SNS Event received:", JSON.stringify(event));

    const message = JSON.parse(event.Records[0].Sns.Message);
    const mail = message.mail;
    const s3Object = message.receipt.action.object;

    if (s3Object.key.startsWith('AMAZON_SES_SETUP_NOTIFICATION')) {
        console.log("Skipping setup notification.");
        return;
    }

    try {
        // 1. S3 నుండి ఇమెయిల్ ఫైల్‌ను పొందండి
        const data = await S3.getObject({
            Bucket: s3Object.bucketName,
            Key: s3Object.key
        }).promise();

        const email = data.Body.toString();
        console.log("Email content loaded from S3.");

        // 2. SES ద్వారా ఇమెయిల్ ను ఫార్వార్డ్ చేయండి
        const sendParams = {
            RawMessage: {
                Data: email 
            },
            Destinations: [FORWARDING_EMAIL],
            Source: FORWARDING_EMAIL, // ఫార్వార్డింగ్ కోసం ఇది SES లో ధృవీకరించబడాలి (Verified)
        };

        await SES.sendRawEmail(sendParams).promise();
        console.log(`Successfully forwarded email to: ${FORWARDING_EMAIL}`);

        // 3. S3 నుండి ఇమెయిల్ ఫైల్‌ను తొలగించండి 
        await S3.deleteObject({
            Bucket: s3Object.bucketName,
            Key: s3Object.key
        }).promise();
        console.log(`Successfully deleted email from S3: ${s3Object.key}`);

    } catch (error) {
        console.error("Error processing email:", error);
        throw error;
    }
};