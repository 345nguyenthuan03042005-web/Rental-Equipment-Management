using Microsoft.EntityFrameworkCore;

namespace WebApi.Models;

public class RentalEquipmentManagementContext : DbContext
{
    public RentalEquipmentManagementContext(DbContextOptions options) : base(options) { }

    public DbSet<Category> Categories { get; set; }
    public DbSet<SubCategory> SubCategories { get; set; }
    public DbSet<Member> Members { get; set; }
    public DbSet<EmailCode> EmailCodes { get; set; }
    public DbSet<Equipment> Equipment { get; set; }
    public DbSet<Cart> Carts { get; set; }
    public DbSet<Status> Statuses { get; set; }
    public DbSet<Rental> Rentals { get; set; }
    public DbSet<RentalDetail> RentalDetails { get; set; }
    public DbSet<RentalPayment> RentalPayments { get; set; }
}
