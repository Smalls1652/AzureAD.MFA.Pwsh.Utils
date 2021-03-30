using System;
using System.Collections;
using System.Collections.Generic;

namespace AzureAD.MFA.Pwsh.Models.Graph.Batch
{
    public class BatchBody
    {
        public BatchBody() { }

        public BatchRequest[] requests { get; set; }

        public Hashtable ConvertToHashtable()
        {
            //Should it be a Dictionary or a Hashtable?
            Hashtable convertedObj = new Hashtable();
            List<Hashtable> requestsHashTable = new List<Hashtable>();

            foreach (BatchRequest item in this.requests)
            {
                requestsHashTable.Add(item.ConvertToHashtable());
            }

            convertedObj.Add("requests", requestsHashTable);

            return convertedObj;
        }
    }
}