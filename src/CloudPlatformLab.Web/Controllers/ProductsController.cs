using CloudPlatformLab.Application.Models;
using CloudPlatformLab.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace CloudPlatformLab.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ProductService _productService;

    public ProductsController(ProductService productService)
    {
        _productService = productService;
    }

    [HttpGet]
    public ActionResult<List<Product>> GetProducts()
    {
        return Ok(_productService.GetProducts());
    }

    [HttpGet("{id}")]
    public ActionResult<Product> GetProduct(int id)
    {
        var product = _productService.GetProduct(id);

        if (product == null)
        {
            return NotFound();
        }

        return Ok(product);
    }
}