using System.Security.Cryptography;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using WebApi.Models;

namespace WebApi.Services;

public class CatalogImages(IWebHostEnvironment environment, IConfiguration configuration,
    RentalEquipmentManagementContext context)
{
    private const string DatabasePrefix = "db-";

    public async Task<string> Upload(IFormFile image, string directory, int nameLength)
    {
        if (image.Length < 12 || image.Length > 5 * 1024 * 1024)
            throw new InvalidDataException("Ảnh phải nhỏ hơn hoặc bằng 5 MB.");

        await using var source = image.OpenReadStream();
        byte[] content = new byte[(int)image.Length];
        await source.ReadExactlyAsync(content);

        string extension;
        if (content.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }))
            extension = ".png";
        else if (content[0] == 255 && content[1] == 216 && content[2] == 255)
            extension = ".jpg";
        else
            throw new InvalidDataException("Ảnh phải có định dạng PNG hoặc JPEG.");

        if (configuration.GetValue<bool>("Images:UseSqlServer"))
        {
            string random = WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(18));
            string name = DatabasePrefix + random[..(nameLength - DatabasePrefix.Length)] + extension;
            await context.Database.ExecuteSqlInterpolatedAsync(
                $"INSERT INTO dbo.CatalogImage (Directory, Name, Content) VALUES ({directory}, {name}, {content})");
            return name;
        }

        string folder = Path.Combine(environment.WebRootPath, directory);
        Directory.CreateDirectory(folder);
        string localName = Guid.NewGuid().ToString("N")[..nameLength] + extension;
        string path = Path.Combine(folder, localName);
        var file = File.Open(path, FileMode.CreateNew);
        try
        {
            await using (file)
                await file.WriteAsync(content);
        }
        catch
        {
            File.Delete(path);
            throw;
        }
        return localName;
    }

    public async Task<IResult> Find(string directory, string name, CancellationToken cancellationToken)
    {
        if (directory is not ("categories" or "equipment") || !IsValidName(name) ||
            !name.StartsWith(DatabasePrefix, StringComparison.Ordinal)) return Results.NotFound();

        byte[]? content = await context.CatalogImages
            .Where(p => p.Directory == directory && p.Name == name)
            .Select(p => p.Content).SingleOrDefaultAsync(cancellationToken);
        return content == null ? Results.NotFound() :
            Results.File(content, name.EndsWith(".png", StringComparison.Ordinal) ? "image/png" : "image/jpeg");
    }

    public void Delete(string directory, string name)
    {
        if (!IsValidName(name)) return;
        if (name.StartsWith(DatabasePrefix, StringComparison.Ordinal))
            context.CatalogImages.Where(p => p.Directory == directory && p.Name == name).ExecuteDelete();
        else
            File.Delete(Path.Combine(environment.WebRootPath, directory, name));
    }

    private static bool IsValidName(string name) => name.Length is > 0 and <= 32 &&
        name.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_' or '.') &&
        Path.GetExtension(name) is ".png" or ".jpg" or ".jpeg";
}
