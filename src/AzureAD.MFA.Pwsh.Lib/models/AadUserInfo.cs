using System;

namespace AzureAD.MFA.Pwsh.Models
{
    public class AadUserInfo {

        public AadUserInfo() {}

        public string UserId { get; set; }

        public string UserPrincipalName { get; set; }

        public MfaMethodType[] MfaMethods { get; set; }

        public int MethodCount { get; set; }

        public int UsableSignInMethodCount { get; set; }
    }
}