using Azure.Identity;
using CloudPlatformLab.Application.Services;

var builder = WebApplication.CreateBuilder(args);

var keyVaultName = builder.Configuration["KeyVaultName"];

if (!string.IsNullOrWhiteSpace(keyVaultName))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri($"https://{keyVaultName}.vault.azure.net/"),
        new DefaultAzureCredential());
}

builder.Services.AddScoped<ProductService>();

var applicationInsightsConnectionString =
    builder.Configuration["ApplicationInsights:ConnectionString"];

if (!string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = applicationInsightsConnectionString;
    });
}

// Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapGet("/health/keyvault", (IConfiguration configuration) =>
{
    var secret = configuration["TestMessage"];

    return string.IsNullOrWhiteSpace(secret)
        ? Results.Problem("Key Vault secret was not loaded.")
        : Results.Ok("Key Vault secret loaded successfully.");
});

app.Run();