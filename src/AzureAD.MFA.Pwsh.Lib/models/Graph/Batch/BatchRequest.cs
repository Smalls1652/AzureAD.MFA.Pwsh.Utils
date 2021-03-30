using System;
using System.Collections;

namespace AzureAD.MFA.Pwsh.Models.Graph.Batch
{
    public class BatchRequest
    {
        public BatchRequest() {}

        public string id { get; set; }
        
        public string method { get; set; }

        public string url { get; set; }

        public Hashtable ConvertToHashtable()
        {
            //Should it be a Dictionary or a Hashtable?
            Hashtable convertedObj = new Hashtable();

            convertedObj.Add("id", this.id);
            convertedObj.Add("method", this.method);
            convertedObj.Add("url", this.url);

            return convertedObj;
        }
    }
}