using Microsoft.AspNetCore.Mvc;
using CloudPlatformLab.Application.Models;
using CloudPlatformLab.Application.Services;

namespace CloudPlatformLab.Web.Controllers
{
    public class HomeController : Controller
    {
        private readonly ProductService _productService = new ProductService();
        public IActionResult Index() 
        {
            var products = _productService.GetProducts();
            return View(products);
        }

        public IActionResult Details(int id)
        {
            var product = _productService.GetProduct(id);
            return View(product);
        }

        public IActionResult About()
        { return View(); }

        public IActionResult Architecture()
        { return View(); }

        public IActionResult AzureServices()
        { return View(); }

        public IActionResult Contact()
        { return View(); }

    }
}
