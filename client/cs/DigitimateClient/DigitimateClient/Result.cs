using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Newtonsoft.Json.Linq;

namespace DigitimateClient
{
    public class Result
    {
        internal Result(JObject jsonResult)
        {
            Success = (bool)jsonResult["success"];
            MobileNumber = (string)jsonResult["userMobileNumber"];
        }

        public bool Success { get; private set; }

        public string MobileNumber { get; private set; }
    }
}
