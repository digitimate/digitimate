using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DigitimateClient
{
    public class Digitimate
    {
        const string BaseUrl = "http://digitimate.com/sendCode?";

        public Digitimate(string developerEmail)
        {
            DeveloperEmail = developerEmail;
            NumberOfDigits = 6;
        }

        public string DeveloperEmail { get; set; }

        public string Message { get; set; }
        
        public int NumberOfDigits { get; set; }

        public async Task<Result> SendCodeAsync(string mobileNumber)
        {
            HttpClient client = new HttpClient();

            string result = await client.GetStringAsync(GetSendCodeUrl(mobileNumber));

            return new Result(JObject.Parse(result));
        }

        public async Task<ValidationResult>CheckCodeAsync(string mobileNumber, int code)
        {
            HttpClient client = new HttpClient();

            string result = await client.GetStringAsync(GetCheckCodeUrl(mobileNumber, code));

            return new ValidationResult(JObject.Parse(result));
        }

        string GetSendCodeUrl(string mobileNumber)
        {
            string url = BaseUrl;

            url += string.Format("developerEmail={0}", Uri.EscapeDataString(DeveloperEmail));
            
            url += string.Format("&userMobileNumber={0}", Uri.EscapeDataString(mobileNumber));
            
            if (Message != null)
                url += string.Format("&message={0}", Uri.EscapeDataString(Message));
            
            if (NumberOfDigits != 6)
                url += string.Format("&numberOfDigits={0}", NumberOfDigits);

            return url;
        }

        string GetCheckCodeUrl(string mobileNumber, int code)
        {
            string url = BaseUrl;

            url += string.Format("developerEmail={0}", Uri.EscapeDataString(DeveloperEmail));

            url += string.Format("&userMobileNumber={0}", Uri.EscapeDataString(mobileNumber));

            url += string.Format("&code={0}", code);

            return url;
        }
    }
}
