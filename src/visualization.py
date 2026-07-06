import matplotlib.pyplot as plt
from config import OUTPUT_FIG_DIR


def plot_time_series(
        df,
        time_column,
        period_label,
        filename,
        tick_step=1,
        show=True):

    # output
    OUTPUT_FIG_DIR.mkdir(parents=True, exist_ok=True)

    # x-axis for positions, labels from time_column
    x_values = range(len(df))
    # labels for x-axis
    # For monthly plots we convert 1, 2, 3, ... into January, February, March, ...
    if time_column == "month":
        month_names = {
            1: "January",
            2: "February",
            3: "March",
            4: "April",
            5: "May",
            6: "June",
            7: "July",
            8: "August",
            9: "September",
            10: "October",
            11: "November",
            12: "December",
    }
        x_labels = df[time_column].map(month_names)
    else:
        x_labels = df[time_column].astype(str)

    # one figure with three rows and one column
    fig, axes = plt.subplots(3, 1, figsize=(12, 10), sharex=True)

    # figure title
    fig.suptitle(
        f"Cost, Leads and Revenue over time ({period_label})",
        weight="bold",
        fontsize=16
    )

    metrics = [
        ("Cost", "cost_2024", "cost_2025", "Cost"),
        ("Leads", "leads_2024", "leads_2025", "Leads"),
        ("Revenue", "revenue_2024", "revenue_2025", "Revenue"),
    ]

    for ax, (title, col_2024, col_2025, y_label) in zip(axes, metrics):
        ax.plot(x_values, df[col_2024], label="2024", marker="o", ms=3, linestyle=":")
        ax.plot(x_values, df[col_2025], label="2025", marker="o", ms=3, linestyle=":")
        ax.set_title(title, weight="bold")
        ax.set_ylabel(y_label)
        ax.grid(True, color="#e0e0e0", linestyle="--", linewidth=0.5)

    # show tick marks on the upper panels, but only label the lowest x-axis
    for ax in axes[:-1]:
        ax.tick_params(axis="x", which="both", bottom=True, labelbottom=False)

    # x-axis labels only on the bottom panel
    axes[2].set_xlabel(period_label)
    axes[2].set_xticks(list(x_values)[::tick_step])
    axes[2].set_xticklabels(x_labels[::tick_step], rotation=45, ha="right")

    # one shared legend in the upper-right corner
    axes[0].legend(loc="upper right")

    # layout
    plt.tight_layout()

    # space for title and legend
    fig.subplots_adjust(top=0.91)

    # output
    output_path = OUTPUT_FIG_DIR / filename
    fig.savefig(output_path, dpi=300, bbox_inches="tight")

    print(f"Plot saved: {output_path}")

    if show:
        plt.show()

    plt.close(fig)