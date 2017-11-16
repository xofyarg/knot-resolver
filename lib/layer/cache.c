
#include "lib/module.h"
#include "lib/cache.h"


/** Module implementation. */
const kr_layer_api_t *cache_layer(struct kr_module *module)
{
	static const kr_layer_api_t _layer = {
		.produce = &cache_peek,
		.consume = &cache_stash,
	};

	return &_layer;
}

KR_MODULE_EXPORT(cache)
