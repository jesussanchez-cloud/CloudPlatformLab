using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CloudPlatformLab.Application.Models;

namespace CloudPlatformLab.Application.Services;

public class ProductService
{
    private readonly List<Product> products = new()
    {
        new Product { ID = 1, Name = "Gaming Laptop", Price = 999.99m },
        new Product { ID = 2, Name = "Gaming Mouse", Price = 49.99m },
        new Product { ID = 3, Name = "Mechanical Keyboard", Price = 89.99m }
    };
    public List<Product> GetProducts() 
    {
        return products;
    }
    

    public Product? GetProduct(int id)
    {
        return products.FirstOrDefault(p => p.ID == id);
    }
}