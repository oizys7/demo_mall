package com.oizys.mall.product.service.impl;

import com.oizys.mall.product.entity.Product;
import com.oizys.mall.product.mapper.ProductMapper;
import com.oizys.mall.product.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ProductServiceImpl implements ProductService {

    @Autowired
    private ProductMapper productMapper;

    @Override
    public Product save(Product product) {
        return productMapper.save(product);
    }

    @Override
    public Optional<Product> findById(Long id) {
        return productMapper.findById(id);
    }

    @Override
    public List<Product> findAll() {
        return productMapper.findAll();
    }

    @Override
    public void deleteById(Long id) {
        productMapper.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return productMapper.existsById(id);
    }

    @Override
    public long count() {
        return productMapper.count();
    }
}