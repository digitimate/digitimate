using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Newtonsoft.Json.Linq;

namespace DigitimateClient
{
    public class ValidationResult : Result
    {
        internal ValidationResult(JObject jsonResult) : base(jsonResult)
        {
            ValidCode = (bool)jsonResult["validCode"];
        }

        public bool ValidCode { get; private set; }
    }
}
