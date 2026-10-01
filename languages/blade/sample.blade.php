{{-- Blade template for the warehouse orders page. --}}
{{--
    A multi-line Blade comment.
    TODO: extract the table into a component.
--}}
@extends('layouts.app')

@use('App\Models\Order')
@use('Illuminate\Support\Str', 'Text')

@section('title', 'Orders')

@push('styles')
    <link rel="stylesheet" href="{{ asset('css/orders.css') }}">
    <style>
        .muted { color: #777; }
        .late  { background: rgba(255, 0, 0, 0.1); }
    </style>
@endpush

@section('content')
    <h1 class="text-xl">{{ __('Orders for :name', ['name' => $user->name]) }}</h1>

    {{-- Echoing: escaped, raw, with defaults and expressions --}}
    <p>{{ $title }} | {{ $count + 1 }} | {{ $name ?? 'Guest' }} | {{ strtoupper($label) }}</p>
    <p>{!! $order->statusBadge() !!} {!! nl2br(e($note)) !!}</p>
    <p>@{{ literal, not parsed by Blade }} @@if escaped directive</p>
    <p>{{ $user?->profile?->name }} {{ $items[0]['sku'] }} {{ Order::count() }} {{ \Carbon\Carbon::now()->format('Y-m-d') }}</p>
    <p>{{ __('messages.welcome') }} @lang('messages.goodbye') {{ trans_choice('items', 3) }}</p>

    @verbatim
        <div class="app">{{ vue.expression }} @if not parsed</div>
    @endverbatim

    {{-- Conditionals --}}
    @if ($orders->isEmpty())
        <p class="muted">No orders yet.</p>
    @elseif ($orders->count() === 1)
        <p>One order.</p>
    @else
        <p>{{ $orders->count() }} orders.</p>
    @endif

    @unless ($user->isAdmin())
        <p>Standard view.</p>
    @endunless

    @isset($orders)
        <span>Orders are set.</span>
    @endisset

    @empty($filters)
        <span>No filters.</span>
    @endempty

    @auth('web')
        <p>Signed in.</p>
    @elseauth('admin')
        <p>Admin.</p>
    @endauth

    @guest
        <a href="{{ route('login') }}">Sign in</a>
    @endguest

    @production
        <script async src="/analytics.js"></script>
    @endproduction

    @env(['local', 'staging'])
        <p>Debug banner</p>
    @endenv

    @can('update', $order)
        <button>Edit</button>
    @elsecan('create', Order::class)
        <button>New</button>
    @else
        <span>Read only</span>
    @endcan

    @cannot('delete', $order)
        <span>Cannot delete</span>
    @endcannot

    @hasSection('sidebar')
        @yield('sidebar')
    @endif

    @sectionMissing('footer')
        <footer>Default footer</footer>
    @endif

    @switch($order->status)
        @case('paid')
            <span class="badge green">Paid</span>
            @break
        @case('late')
            <span class="badge red">Late</span>
            @break
        @default
            <span class="badge">Pending</span>
    @endswitch

    {{-- Loops --}}
    <table>
        @foreach ($orders as $order)
            <tr @class(['paid' => $order->isPaid(), 'late' => $order->isLate()]) @style(['font-weight: bold' => $loop->first])>
                <td>{{ $loop->iteration }} / {{ $loop->count }}</td>
                <td>{{ $order->number }}</td>
                <td>{{ $order->total->format() }}</td>
                <td>{!! $order->statusBadge() !!}</td>
                @if ($loop->last) <td>last</td> @endif
                @continue($order->isHidden())
                @break($loop->index > 100)
            </tr>
        @endforeach
    </table>

    @forelse ($items as $key => $item)
        <li>{{ $key }}: {{ $item->name }}</li>
    @empty
        <li>No items</li>
    @endforelse

    @for ($i = 0; $i < 3; $i++)
        <span>{{ $i }}</span>
    @endfor

    @while ($queue->hasMore())
        <span>{{ $queue->next() }}</span>
    @endwhile

    {{ $orders->links() }}

    {{-- Forms and attributes --}}
    <form method="POST" action="{{ route('orders.store') }}">
        @csrf
        @method('PUT')
        <input name="sku" value="{{ old('sku') }}" @required(true) @disabled($locked) @readonly($frozen)>
        <input type="checkbox" name="active" @checked(old('active', $order->active))>
        <option @selected($order->id === $selected)>One</option>
        @error('sku')
            <span class="error">{{ $message }}</span>
        @enderror
        <button type="submit" {{ $attributes->merge(['class' => 'btn']) }}>Save</button>
    </form>

    {{-- Includes and components --}}
    @include('partials.summary', ['count' => $count])
    @includeIf('partials.optional')
    @includeWhen($showExtra, 'partials.extra', ['data' => $extra])
    @includeUnless($hideExtra, 'partials.more')
    @includeFirst(['custom.header', 'header'])
    @each('partials.row', $orders, 'order', 'partials.empty')

    <x-alert type="error" :message="$message" class="mb-4" {{ $attributes }}>
        <x-slot:title>Heads up</x-slot>
        <x-slot name="footer">Footer text</x-slot>
        Body of the alert
    </x-alert>
    <x-forms.input name="email" :value="old('email')" wire:model.live="email" />
    <livewire:order-table :orders="$orders" />
    @livewire('order-stats')
    <x-dynamic-component :component="$componentName" class="mt-4" />

    @component('components.card', ['title' => 'Legacy'])
        @slot('footer') Footer @endslot
        Card body
    @endcomponent

    {{-- Stacks, once, props, inject, session --}}
    @once
        @push('scripts')
            <script>
                const orders = @json($orders);
                const config = @js($config);
                document.querySelectorAll('.badge').forEach((el, i) => {
                    el.dataset.index = `${i}`;
                });
            </script>
        @endpush
    @endonce

    @prepend('scripts')
        <script>console.log('first');</script>
    @endprepend

    @props(['type' => 'info', 'message'])
    @aware(['theme' => 'light'])
    @inject('metrics', 'App\Services\MetricsService')
    @session('status')
        <div class="alert">{{ $value }}</div>
    @endsession
    <p>{{ $metrics->summary() }}</p>

    @php
        $count = $orders->count();
        $label = Text::title('orders');
        $totals = collect($orders)->map(fn ($o) => $o->total)->sum();
    @endphp
    @php($quick = $count * 2)

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @stack('scripts')
    @csrf
    @dd($orders)
    @dump($count)
@endsection

@section('footer')
    <small>&copy; {{ date('Y') }} Acme Logistics</small>
@show

@yield('extra', 'default extra')
@parent
@stop
@append
@overwrite
@lang('done')
@extends('layouts.app')

{{-- ── Further constructs ─────────────────────────────────────────── --}}
@php
    use App\Models\Product;
    namespace_declared_in_php_block();
    $matrix = [[1, 2], [3, 4]];
    $closure = function ($x) use ($matrix): int { return $x * 2; };
    $arrow = fn (int $x): int => $x + 1;
    $match = match (true) { $count > 10 => 'many', default => 'few' };
    $nullsafe = $user?->address?->city ?? 'unknown';
    $heredoc = <<<TXT
        Heredoc with {$count} interpolation
        TXT;
    enum_exists(\App\Enums\Status::class);
@endphp

@pushOnce('scripts', 'unique-key')
    <script src="/once.js"></script>
@endPushOnce

@prependOnce('styles')
    <style>.first { order: -1; }</style>
@endPrependOnce

@fragment('table')
    <table>{{ $slot ?? '' }}</table>
@endfragment

@use('App\Helpers\Money', 'M')

@error('email', 'login')
    <p class="error">{{ $message }}</p>
@enderror

@push('modals')
    <div id="modal" x-data="{ open: false }" @click.away="open = false" :class="{ 'hidden': !open }">
        <button @click="open = !open" x-text="open ? 'Close' : 'Open'"></button>
    </div>
@endpush

@auth
    @can('manage', $warehouse)
        <a href="{{ route('warehouses.edit', ['warehouse' => $warehouse->id, 'tab' => 'stock']) }}">Edit</a>
    @endcan
@endauth

@if (config('app.debug') && app()->environment('local'))
    @dump($errors->all())
@endif

@forelse ($warehouses as $index => $warehouse)
    @continue($warehouse->archived)
    <x-warehouse-card :warehouse="$warehouse" :index="$index" :highlight="$loop->first" />
@empty
    <p>@lang('No warehouses')</p>
@endforelse

@switch(true)
    @case($count > 100)
        Large
        @break
    @default
        Small
@endswitch

@includeIf('missing.view', ['a' => 1])

<x-layout :title="__('Stock')" :user="$user">
    <x-slot:header class="flex">
        <h2>{{ __('Header') }}</h2>
    </x-slot>

    <x-input type="text" name="sku" :value="old('sku', $item->sku ?? '')" required />

    <x-button wire:click.prevent="save" wire:loading.attr="disabled" x-on:click="$dispatch('saved')">
        {{ __('Save') }}
    </x-button>
</x-layout>

<script>
    const stock = @json($items, JSON_PRETTY_PRINT);
    const url = "{{ route('stock.index') }}";
    const raw = {!! json_encode($config) !!};
    @if ($debug)
        console.debug('debug on');
    @endif
</script>

<style>
    .low { color: {{ $lowColour }}; }
</style>

<a href="{{ url('/stock') }}" {{ $attributes->class(['link', 'active' => $active])->merge(['data-id' => $id]) }}>Stock</a>
<input value="{{ $old ?? '' }}" @disabled(! $editable) @readonly($locked) @required($must)>

{{ Js::from($data) }}
{{ Illuminate\Support\Number::currency($total, 'USD') }}
{{ $loop->parent->iteration }} {{ $loop->depth }} {{ $loop->remaining }} {{ $loop->even ? 'even' : 'odd' }}
{{ $slot->isEmpty() ? 'default' : $slot }}
{{ $errors->first('sku') }} {{ session('status') }} {{ csrf_token() }} {{ auth()->user()->name ?? 'guest' }}
@{{ not parsed }} @@csrf @@if

{{-- TODO: replace inline Alpine with Livewire. --}}
