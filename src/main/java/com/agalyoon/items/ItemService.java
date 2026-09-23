package com.agalyoon.items;

import java.util.List;

import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ItemService {
    private final ItemRepository repository;

    public ItemService(ItemRepository repository) {
        this.repository = repository;
    }

    public List<ItemResponse> list() {
        return repository.findAll(Sort.by("id")).stream().map(ItemResponse::from).toList();
    }

    public ItemResponse get(long id) {
        return ItemResponse.from(find(id));
    }

    @Transactional
    public ItemResponse create(ItemRequest request) {
        Item item = new Item(request.name(), request.description(), request.price(), request.quantity());
        return ItemResponse.from(repository.save(item));
    }

    @Transactional
    public ItemResponse update(long id, ItemRequest request) {
        Item item = find(id);
        item.update(request.name(), request.description(), request.price(), request.quantity());
        return ItemResponse.from(item);
    }

    @Transactional
    public void delete(long id) {
        repository.delete(find(id));
    }

    private Item find(long id) {
        return repository.findById(id).orElseThrow(() -> new ItemNotFoundException(id));
    }
}
