// lambda/bounce_handler_lambda.js

exports.handler = async (event) => {
    try {
        const snsMessage = JSON.parse(event.Records[0].Sns.Message);
        const notificationType = snsMessage.notificationType;

        console.log(`--- SES NOTIFICATION RECEIVED: ${notificationType} ---`);

        if (notificationType === "Bounce") {
            const bounce = snsMessage.bounce;
            console.log(`BOUNCE: Recipients: ${JSON.stringify(bounce.bouncedRecipients)}`);
            console.log(`Reason: ${bounce.bounceType} - ${bounce.bounceSubType}`);
        } else if (notificationType === "Complaint") {
            const complaint = snsMessage.complaint;
            console.log(`COMPLAINT: Recipients: ${JSON.stringify(complaint.complainedRecipients)}`);
            console.log(`Feedback Type: ${complaint.complaintFeedbackType}`);
        }

        return { statusCode: 200, body: "Notification Processed" };
    } catch (error) {
        console.error("ERROR processing notification:", error);
        return { statusCode: 500, body: "Error" };
    }
};