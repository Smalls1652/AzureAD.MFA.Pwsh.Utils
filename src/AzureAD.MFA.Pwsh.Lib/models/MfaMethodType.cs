using System;

namespace AzureAD.MFA.Pwsh.Models
{
    public class MfaMethodType
    {
        public MfaMethodType() { }

        public MfaMethodType(string methodName, string methodId, bool isUsableAsPrimary)
        {
            MethodName = methodName;
            MethodId = methodId;
            IsUsableAsPrimary = isUsableAsPrimary;
        }

        public string MethodName { get; set; }

        public string MethodId { get; set; }

        public bool IsUsableAsPrimary { get; set; }

        public override string ToString() {
            return this.MethodName;
        }
    }
}