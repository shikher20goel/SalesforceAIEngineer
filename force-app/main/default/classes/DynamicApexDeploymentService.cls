public class DynamicApexDeploymentService {
    private static final String NAMED_CREDENTIAL = 'callout:ToolingAPI';

    // Method to deploy any Apex code dynamically using Tooling API
    @InvocableMethod(label='Deploy Apex Code' description='Deploy Apex code using the Tooling API')
    public static List<DeploymentResult> deployApexCode(List<DeploymentRequest> deploymentRequests) {
        List<DeploymentResult> results = new List<DeploymentResult>();
        
        for (DeploymentRequest request : deploymentRequests) {
            DeploymentResult result = new DeploymentResult();
            try {
                // Construct the Tooling API endpoint based on the object type (ApexClass, ApexTrigger, etc.)
                //String toolingApiEndpoint = '/services/data/v54.0/tooling/sobjects/' + request.objectType + '/';
                String toolingApiEndpoint = NAMED_CREDENTIAL + '/services/data/v59.0/tooling/sobjects/' + request.objectType+'/';


                // Create a HTTP request to call the Tooling API
                System.debug(' Before clean up >>>'+request.jsonPayload);
                String jsonPayload = cleanJsonInput(request.jsonPayload);
                System.debug(' After clean up >>>'+jsonPayload);
                HttpRequest req = new HttpRequest();
                req.setEndpoint( toolingApiEndpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(jsonPayload);

                // Send the HTTP request and get the response
                Http http = new Http();
                HttpResponse res = http.send(req);

                // Log response for debugging
                System.debug('Response Status: ' + res.getStatus());
                System.debug('Response Body: ' + res.getBody());

                // Check the response status
                if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
                    result.status = 'Code deployed successfully: ' + res.getBody();
                } else {
                    result.status = 'Response Error Status  :' +res.getStatus() + ' , Response Body  : ' + res.getBody();
                }

            } catch (Exception e) {
                result.status = 'Exception: ' + e.getMessage();
            }
            results.add(result);
        }
        return results;
    }

public static String cleanJsonInput(String input) {
    if (String.isEmpty(input)) {
        return input;
    }
    
    input = input.replaceAll('[^\\x20-\\x7E]', ''); // Remove any unexpected non-printable characters
    //input = input.replaceAll('<.*?>', '');  // Remove HTML tags
   // input = input.replaceAll('<(?!/?(Set|List|Map|Integer|Double|Boolean|String|Id|Long|Decimal|Date|Datetime|SObject)[^>]*>)[^>]*>', '');
   // input = input.replaceAll('<(?!/?(Set|List|Map|Integer|Double|Boolean|String|Id|Long|Decimal|Date|Datetime|SObject|Object)[^>]*>)(?!\\[)[^>]*>', '');
   // input = input.replaceAll('<(?!/?(Set|List|Map|Integer|Double|Boolean|String|Id|Long|Decimal|Date|Datetime|SObject|Object)\\s*<[\\w,\\s]*>)[^>]*>', '');
    input = input.replaceAll('<(?!/?(\\w+\\s*<[\\w,\\s]*>)\\s*)[^>]+>', '');
   // // Decode all HTML-encoded characters
    input = input.unescapeHtml4();
    //input = input.replaceAll('&#124;', '|'); 
  
    input = decodeHtmlEntities(input);
    input = input.replaceAll('\\+','__PLUS__'); 
    input = EncodingUtil.urlDecode(input, 'UTF-8');
    input = input.replaceAll('__PLUS__','\\+'); 
    return input.trim();
}
public static String decodeHtmlEntities(String input) {
    // Regular expression to match numeric HTML entities (like &#124;)
    Pattern p = Pattern.compile('&#([0-9]+);');
    Matcher m = p.matcher(input);
    
    String result = '';
    Integer lastEnd = 0;
   
    while (m.find()) {
        System.debug('>>>34>>');
        // Append the text before the match
        result += input.substring(lastEnd, m.start());

        // Extract the numeric value (e.g., 124 from &#124;)
        Integer codePoint = Integer.valueOf(m.group(1));
        System.debug('>>>codePoint>>'+codePoint);
        // Convert the numeric code to the corresponding character and append it as a String
        result += String.fromCharArray( new List<integer> { codePoint } );// Convert to character using Char array
        
        lastEnd = m.end(); // Update the last match position
    }

    // Append any remaining text after the last match
    result += input.substring(lastEnd);

    return result;
}

    // Define a class to capture the Flow input parameters
    public class DeploymentRequest {
        @InvocableVariable(label='Object Type' description='The object type to deploy (e.g., ApexClass, ApexTrigger)')
        public String objectType;

        @InvocableVariable(label='JSON Payload' description='The JSON payload for the deployment')
        public String jsonPayload;
    }

    // Define a class to capture the result of the deployment process
    public class DeploymentResult {
        @InvocableVariable(label='Status' description='The status message for the deployment result')
        public String status;
    }
}