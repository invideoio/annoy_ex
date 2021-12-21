#include "annoylib.h"
#include "kissrandom.h"
#include <erl_nif.h>

using namespace Annoy;

#ifdef ANNOYLIB_MULTITHREADED_BUILD
  typedef AnnoyIndexMultiThreadedBuildPolicy AnnoyIndexThreadedBuildPolicy;
#else
  typedef AnnoyIndexSingleThreadedBuildPolicy AnnoyIndexThreadedBuildPolicy;
#endif
template class AnnoyIndexInterface<int32_t, float>;

typedef AnnoyIndex<int32_t, float, Angular, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexAngular;
typedef AnnoyIndex<int32_t, float, DotProduct, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexDotProduct;
typedef AnnoyIndex<int32_t, float, Euclidean, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexEuclidean;
typedef AnnoyIndex<int32_t, float, Manhattan, Kiss64Random, AnnoyIndexThreadedBuildPolicy> AnnoyIndexManhattan;

static ErlNifResourceType* ANNOY_INDEX_RESOURCE;

typedef struct
{
   AnnoyIndexInterface<int32_t, float>* idx;
} ex_annoy; 

// extern "C"
// {
    // ERL_NIF_TERM annoy_new_index(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_new_filter(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_insert(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_contains(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

    // ERL_NIF_TERM ebloom_clear(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

    // ERL_NIF_TERM ebloom_size(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_elements(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_effective_fpp(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

    // ERL_NIF_TERM ebloom_filter_intersect(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_filter_union(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_filter_difference(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

    // ERL_NIF_TERM ebloom_serialize(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    // ERL_NIF_TERM ebloom_deserialize(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);

    // void ebloom_filter_dtor(ErlNifEnv* env, void* arg);
    // int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info);


  // ERL_NIF_INIT(ebloom, funcs, &on_load, NULL, NULL, NULL);
//}


ERL_NIF_TERM annoy_new_index(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) 
{
  int f;
  char metric[16];
  
  if (!enif_get_int(env, argv[0], &f)) {
    return enif_make_badarg(env);
    }

  if(!enif_get_atom(env, argv[1], metric, sizeof(metric), ERL_NIF_LATIN1)) {
    return enif_make_badarg(env);
  }

  ex_annoy* handle = (ex_annoy*)enif_alloc_resource(ANNOY_INDEX_RESOURCE, sizeof(ex_annoy));

  if(!strncmp(metric, "dot", sizeof(metric))) {
    handle->idx = new AnnoyIndex<int32_t, float, DotProduct, Kiss64Random, AnnoyIndexThreadedBuildPolicy>(f);
  } else if(!strncmp(metric, "euclidian", sizeof(metric))) {
    handle->idx = new AnnoyIndex<int32_t, float, Euclidean, Kiss64Random, AnnoyIndexThreadedBuildPolicy>(f);
  } else if(!strncmp(metric, "manhattan", sizeof(metric))) {
    handle->idx = new AnnoyIndexManhattan(f);
  } else {
    handle->idx = new AnnoyIndexAngular(f);
  }

  ERL_NIF_TERM result = enif_make_resource(env, handle);
  enif_release_resource(handle);
  
  return result;
}

// static ERL_NIF_TERM
// load(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
//   AnnoyIndexInterface<int32_t, float>* ptr;
//   // filename to load
//   // prefault or not

//   if(!enif_get_resource(env, argv[0], ANNOY_INDEX_RESOURCE, (void**)&ptr )) {
//     return enif_make_badarg(env);
//   }

// } 

void annoy_index_dtor(ErlNifEnv* env, void* arg)
{
    ex_annoy* handle = (ex_annoy*)arg;
    delete handle->idx;
}

int on_load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info)
{
    ErlNifResourceFlags flags = (ErlNifResourceFlags)(ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER);
    ANNOY_INDEX_RESOURCE = enif_open_resource_type(env, "Elixir.AnnoyEx", "annoy_index_resource", &annoy_index_dtor, flags, 0);
                                                    
    return 0;
}

    static ErlNifFunc funcs[] =
    {
        { "new", 2, annoy_new_index, 0 }
        // {"new",           3, ebloom_new_filter},
        // {"insert",        2, ebloom_insert},
        // {"contains",      2, ebloom_contains},
        // {"clear",         1, ebloom_clear},
        // {"size",          1, ebloom_size},
        // {"elements",      1, ebloom_elements},
        // {"effective_fpp", 1, ebloom_effective_fpp},
        // {"intersect",     2, ebloom_filter_intersect},
        // {"union",         2, ebloom_filter_union},
        // {"difference",    2, ebloom_filter_difference},
        // {"serialize",     1, ebloom_serialize},
        // {"deserialize",   1, ebloom_deserialize}
    };

  ERL_NIF_INIT(Elixir.AnnoyEx, funcs, &on_load, NULL, NULL, NULL)