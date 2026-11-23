using System.Data;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using WebApi.Models;
using WebApi.Services;

public class MemberRepository : BaseRepository
{
    public MemberRepository(RentalEquipmentManagementContext context) : base(context) {}
    public IEnumerable<Member> GetMembers()
    {
        return context.Members.ToList();
    }
    public int Add(Member obj)
    {
        if (context.Members.Where(p => p.Email == obj.Email).Any()) return -1;
        context.Members.Add(obj);
        return context.SaveChanges();
    }
    public Member? GetMember(string id)
    {
        return context.Members.Find(id);
    }
    public Member? GetMemberByEmail(string email)
    {
        //return context.Members.Where(p => p.Email == email).First();
        return context.Members.FirstOrDefault(p=> p.Email == email);
    }
    public int Update(string id, string givenName, string? surname, Role role, bool isActive)
    {
        return context.Members.Where(p => p.Id == id)
            .ExecuteUpdate(p => p.SetProperty(x => x.GivenName, givenName)
                .SetProperty(x => x.Surname, surname)
                .SetProperty(x => x.Role, role)
                .SetProperty(x => x.IsActive, isActive));
    }

    public int ChangePassword(string id, string currentPassword, string newPassword)
    {
        var member = GetMember(id);
        if (member == null || !member.IsActive ||
            !ValidPasswordLength(currentPassword) || !ValidPasswordLength(newPassword) ||
            !BCrypt.Net.BCrypt.Verify(currentPassword, member.Password))
            return 0;

        var oldHash = member.Password;
        var newHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        return context.Members.Where(p => p.Id == id && p.Password == oldHash && p.IsActive)
            .ExecuteUpdate(p => p.SetProperty(x => x.Password, newHash));
    }

    private static bool ValidPasswordLength(string password)
        => System.Text.Encoding.UTF8.GetByteCount(password) <= 72;

    public int SaveEmailCode(string memberId, string purpose, string hash)
    {
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        var code = context.EmailCodes.Find(memberId, purpose);
        DateTime now = DateTime.UtcNow;
        if (code != null && code.SentAt > now.AddMinutes(-1)) return 0;
        if (code == null)
        {
            code = new EmailCode { MemberId = memberId, Purpose = purpose };
            context.EmailCodes.Add(code);
        }
        code.CodeHash = hash;
        code.SentAt = now;
        code.Attempts = 0;
        context.SaveChanges();
        transaction.Commit();
        return 1;
    }

    public bool UseEmailCode(string email, string purpose, string input, string secret, string? password)
    {
        var member = GetMemberByEmail(email);
        if (member == null || !member.IsActive || (password != null && !ValidPasswordLength(password)))
            return false;

        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);
        var code = context.EmailCodes.Find(member.Id, purpose);
        if (code == null || code.Attempts >= 5 || code.SentAt < DateTime.UtcNow.AddMinutes(-10))
            return false;

        string hash = HashEmailCode(member.Id!, purpose, input, secret);
        if (!CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(hash), Encoding.ASCII.GetBytes(code.CodeHash)))
        {
            code.Attempts++;
            context.SaveChanges();
            transaction.Commit();
            return false;
        }

        if (password == null) member.EmailVerified = true;
        else
        {
            member.Password = BCrypt.Net.BCrypt.HashPassword(password);
            member.SecurityVersion++;
        }
        context.EmailCodes.Remove(code);
        context.SaveChanges();
        transaction.Commit();
        return true;
    }

    public static string HashEmailCode(string id, string purpose, string code, string secret)
        => Convert.ToHexString(HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret),
            Encoding.UTF8.GetBytes($"{id}:{purpose}:{code}")));

    public LoginResponse Login(LoginModel obj, IConfiguration configuration)
    {
        Member? member = GetMemberByEmail(obj.Email);
        if(member is null || !member.IsActive) return new LoginResponse
        {
            Success = false,
            Message = "Email invalid"
        };
        if(ValidPasswordLength(obj.Password) && BCrypt.Net.BCrypt.Verify(obj.Password, member.Password))
        {
            if (!member.EmailVerified && configuration.GetValue<bool>("Email:RequireVerification"))
                return new LoginResponse { Success = false, Message = "Hãy xác thực email trước khi đăng nhập." };

            return new LoginResponse
        {
            Success = true, 
            Message = "Login Success",
            Token = Helper.GenerateToken(member, configuration)
        };}
        return new LoginResponse
        {
            Success = false,
            Message = "Password invalid"
        };
    }
}