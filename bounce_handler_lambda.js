exports.handler = async (event) => {
    console.log('Received SES Notification:', JSON.stringify(event, null, 2));

    try {
        const snsMessage = JSON.parse(event.Records[0].Sns.Message);
        const notificationType = snsMessage.notificationType;

        if (notificationType === 'Bounce' || notificationType === 'Complaint') {
            
            const mail = snsMessage.mail;
            const recipients = notificationType === 'Bounce' 
                               ? snsMessage.bounce.bouncedRecipients 
                               : snsMessage.complaint.complainedRecipients;

            console.log(`Processing ${notificationType} notification for Message ID: ${mail.messageId}`);
            
            for (const recipient of recipients) {
                const emailAddress = recipient.emailAddress || recipient.address;
                const diagnosticCode = recipient.diagnosticCode || 'N/A';
                
                console.log(`--- Recipient: ${emailAddress} | Type: ${notificationType} | Diagnostic: ${diagnosticCode}`);
                
                // 🛑 కీలకమైన పని: ఈ ఇమెయిల్ అడ్రస్‌ను మీ Suppression List డేటాబేస్‌లో సేవ్ చేయాలి.
                // ఉదాహరణకు, ఇక్కడ DynamoDB లో ఆ అడ్రస్‌ను 'DISABLED' అని మార్క్ చేయవచ్చు.
                
                // ప్రస్తుతం ఇది కేవలం లాగింగ్ మాత్రమే చేస్తుంది.
                // అసలు కోడ్‌లో AWS SDK (DynamoDB) ఉపయోగించి డేటాబేస్‌లో అప్‌డేట్ చేయాలి.
            }
            
            console.log("Notification processed successfully.");
        } else {
            console.log(`Skipping notification type: ${notificationType}`);
        }
        
    } catch (error) {
        console.error("Error processing SNS message:", error);
        return { statusCode: 500, body: 'Error processing message' };
    }
};