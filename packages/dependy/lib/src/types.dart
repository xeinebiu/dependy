typedef DependyResolve = T Function<T extends Object>();

typedef DependyDispose<T> = void Function(T);

typedef DependyFactory<T extends Object> = T Function(
  DependyResolve dependencies,
);
