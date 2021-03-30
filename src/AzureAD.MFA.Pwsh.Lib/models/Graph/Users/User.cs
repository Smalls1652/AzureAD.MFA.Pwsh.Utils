using System;

namespace AzureAD.MFA.Pwsh.Models.Graph.Users
{
    public class User
    {
        public User() { }

        public string UserId { get; set; }

        public string UserPrincipalName { get; set; }

        public Nullable<DateTime> LastSignInDateTime { get; set; }

        public override string ToString()
        {
            return this.UserPrincipalName;
        }
    }
}