namespace WebApi.Models;

public class SiteProvider : BaseProvider
{
    public SiteProvider(IHttpContextAccessor accessor) : base(accessor)
    {
    }
    //fields
    CategoryRepository? category;
    //properties
    public CategoryRepository Category => category ??= new CategoryRepository(Context);
    SubCategoryRepository? subCategory;
    public SubCategoryRepository SubCategory => subCategory ??= new SubCategoryRepository(Context);
    MemberRepository? member;
    //properties
    public MemberRepository Member => member ??= new MemberRepository(Context);
    EquipmentRepository? equipment;
    public EquipmentRepository Equipment => equipment ??= new EquipmentRepository(Context);
    CartRepository? cart;
    //properties
    public CartRepository Cart => cart ??= new CartRepository(Context);
    RentalRepository? rental;
    public RentalRepository Rental => rental ??= new RentalRepository(Context);
    StatusRepository? status;
    PaymentRepository? payment;
    public PaymentRepository Payment => payment ??= new PaymentRepository(Context);

    public StatusRepository Status => status ??= new StatusRepository(Context);
}