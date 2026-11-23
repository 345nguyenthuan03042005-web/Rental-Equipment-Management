using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using WebApi.Models;

namespace WebApi.Services;

public static class Helper
{

    public static string GenerateToken(Member member, IConfiguration configuration)
    {
        List<Claim> claims  = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, member.Id!),
            new Claim(ClaimTypes.Name, string.IsNullOrEmpty(member.Surname) ? member.GivenName : member.Surname + " " + member.GivenName),
            new Claim(ClaimTypes.Email, member.Email),
            new Claim(ClaimTypes.GivenName, member.GivenName),
            new Claim(ClaimTypes.Role, member.Role.ToString()),
            new Claim("ver", member.SecurityVersion.ToString(System.Globalization.CultureInfo.InvariantCulture))
        };
        if(!string.IsNullOrEmpty(member.Surname)) claims.Add(new Claim(ClaimTypes.Surname, member.Surname));
        JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();
        SymmetricSecurityKey key = new SymmetricSecurityKey(Encoding.ASCII.GetBytes(configuration["Jwt:SecretKey"] ?? throw new KeyNotFoundException("Jwt:SecretKey")));
        JwtSecurityToken token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(int.Parse(configuration["Jwt:Expires"] ?? throw new KeyNotFoundException("Jwt:Expires"))),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature)
        );
        return handler.WriteToken(token);
    }

    public static Task<string> UploadEquipmentImage(IFormFile image, string webRoot)
        => UploadImage(image, webRoot, "equipment", 24);

    public static async Task<string> UploadImage(IFormFile image, string webRoot, string directory, int nameLength)
    {
        if (image.Length < 12 || image.Length > 5 * 1024 * 1024)
            throw new InvalidDataException("Ảnh phải nhỏ hơn hoặc bằng 5 MB.");

        await using var source = image.OpenReadStream();
        byte[] header = new byte[12];
        await source.ReadExactlyAsync(header);
        string extension;
        if (header.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }))
            extension = ".png";
        else if (header[0] == 255 && header[1] == 216 && header[2] == 255)
            extension = ".jpg";
        else
            throw new InvalidDataException("Ảnh phải có định dạng PNG hoặc JPEG.");

        string folder = Path.Combine(webRoot, directory);
        Directory.CreateDirectory(folder);
        string name = Guid.NewGuid().ToString("N")[..nameLength] + extension;
        string path = Path.Combine(folder, name);
        try
        {
            await using var file = File.Open(path, FileMode.CreateNew);
            await file.WriteAsync(header);
            await source.CopyToAsync(file);
        }
        catch
        {
            File.Delete(path);
            throw;
        }
        return name;
    }

    public static void DeleteEquipmentImage(string webRoot, string name)
        => DeleteImage(webRoot, "equipment", name);

    public static void DeleteImage(string webRoot, string directory, string name)
    {
        if (name.Length > 0 && name.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_' or '.')
            && Path.GetExtension(name) is ".png" or ".jpg" or ".jpeg")
            File.Delete(Path.Combine(webRoot, directory, name));
    }
}
