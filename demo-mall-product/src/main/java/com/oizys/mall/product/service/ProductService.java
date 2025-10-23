package com.oizys.mall.product.service;

import com.oizys.mall.product.entity.Product;
import java.util.List;
import java.util.Optional;

public interface ProductService {
    Product save(Product product);
    Optional<Product> findById(Long id);
    List<Product> findAll();
    void deleteById(Long id);
    boolean existsById(Long id);
    long count();
}